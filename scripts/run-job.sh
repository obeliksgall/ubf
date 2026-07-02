#!/bin/bash

# Wczytanie zmiennych środowiskowych Dockera (niezbędne dla harmonogramu Cron)
set -a
[ -f /etc/environment ] && source /etc/environment
set +a

JOB_NAME="$1"
NOTIFY_LEVEL=${NOTIFY_LEVEL:-0}
JOB_FILE="/jobs/${JOB_NAME}.yaml"

if [ -z "$JOB_NAME" ]; then
    echo "Błąd: Nie podano nazwy zadania!"
    exit 1
fi

# 📁 OBSŁUGA LOGÓW (Current & Archive)
DIR_CURRENT="/logs/current"
DIR_ARCHIVE="/logs/archive"
LOG_FILE="${DIR_CURRENT}/${JOB_NAME}.log"

# Upewniamy się, że odpowiednie katalogi istnieją
mkdir -p "$DIR_CURRENT" "$DIR_ARCHIVE"

# Jeśli istnieje stary log z poprzedniego uruchomienia, przenosimy go do archiwum z datą
if [ -f "$LOG_FILE" ]; then
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    mv "$LOG_FILE" "${DIR_ARCHIVE}/${JOB_NAME}_${TIMESTAMP}.log"
fi

# ♻️ Czyszczenie archiwum: usuwamy logi starsze niż 90 dni
find "$DIR_ARCHIVE" -type f -name "*.log" -mtime +90 -exec rm {} \;

# Magia bash: od tego momentu cały tekst ze skryptu (echo, błędy i rclone) leci na ekran ORAZ do pliku
exec > >(tee "$LOG_FILE") 2>&1

if [ ! -f "$JOB_FILE" ]; then
    echo "Błąd: Plik joba nie istnieje: $JOB_FILE"
    exit 1
fi

# 🔒 BLOKADA flock
LOCK_FILE="/lock/${JOB_NAME}.lock"
exec 200>"$LOCK_FILE"
flock -n 200 || {
    MSG="⚠️ Zadanie $JOB_NAME już trwa — przerwano duplikat."
    echo "$MSG"
    [ "$NOTIFY_LEVEL" -ge 0 ] && bash /scripts/notify-discord.sh "$MSG"
    exit 1
}

# 🌐 TEST DOSTĘPU DO INTERNETU
INTERNET_LOG="/logs/internet.log"

check_internet() {
    # Test DNS
    if ! getent hosts google.com >/dev/null 2>&1; then
        echo "$(date) ❌ Brak internetu (DNS niedostępny)" >> "$INTERNET_LOG"
        return 1
    fi

    # Test HTTP
    if ! wget -q --spider --timeout=2 https://www.google.com; then
        echo "$(date) ❌ Brak internetu (HTTP niedostępny)" >> "$INTERNET_LOG"
        return 1
    fi

    return 0
}

if ! check_internet; then
    echo "❌ Brak internetu — backup przerwany."
    exit 1
fi


# 📄 ODCZYT YAML (yq)
TYPE=$(yq '.type // .mode // "sync"' "$JOB_FILE")
DEST=$(yq '.dest' "$JOB_FILE")
RETENTION=$(yq '.retention_days // 0' "$JOB_FILE")
TRANSFERS=$(yq '.transfers // 4' "$JOB_FILE")
CHECKERS=$(yq '.checkers // 2' "$JOB_FILE")

# Lista źródeł jako tablica bash
mapfile -t SOURCES < <(yq '.source[]' "$JOB_FILE")

if [ ${#SOURCES[@]} -eq 0 ]; then
    echo "Błąd: Brak źródeł w jobie!"
    exit 1
fi

# 🛡 WALIDACJA ŹRÓDEŁ
for SRC in "${SOURCES[@]}"; do
    if [[ "$SRC" == :local:* ]]; then
        LOCAL_PATH="${SRC/:local:/}"
        if [ ! -d "$LOCAL_PATH" ]; then
            MSG="❌ BŁĄD: Lokalny katalog nie istnieje: $LOCAL_PATH"
            echo "$MSG"
            bash /scripts/notify-discord.sh "$MSG"
            exit 1
        fi
    fi
done

# 🔔 Powiadomienie startowe
[ "$NOTIFY_LEVEL" -ge 1 ] && bash /scripts/notify-discord.sh "🚀 Start backupu: $JOB_NAME"

echo "=== UBF JOB: $JOB_NAME ==="
echo "Typ: $TYPE"
echo "Dest: $DEST"
echo "Źródła: ${SOURCES[*]}"

# 🚀 WYKONANIE BACKUPU
for SRC in "${SOURCES[@]}"; do
    echo "Backup źródła: $SRC"

    # Pobieramy nazwę ostatniego folderu ze ścieżki (np. z "/data/Send" robi się "Send")
    SRC_BASENAME=$(basename "$SRC")
    
    # Dołączamy tę nazwę do ścieżki docelowej, aby źródła się nie nadpisywały
    TARGET_DEST="${DEST}/${SRC_BASENAME}"

    if [ "$TYPE" = "sync" ]; then
        if [ "$RETENTION" -gt 0 ]; then
            # Bezpieczna retencja: pliki usuwane ze źródła trafiają do folderu z datą
            ARCHIVE_DIR="${DEST}_archive/$(date +%Y-%m-%d)_${SRC_BASENAME}"
            rclone sync "$SRC" "$TARGET_DEST" --backup-dir="$ARCHIVE_DIR" --transfers "$TRANSFERS" --checkers "$CHECKERS" --stats=5s --stats-one-line --log-level INFO
			#--progress
        else
            rclone sync "$SRC" "$TARGET_DEST" --transfers "$TRANSFERS" --checkers "$CHECKERS" --stats=5s --stats-one-line --log-level INFO
			#--progress
        fi
    elif [ "$TYPE" = "copy" ]; then
        rclone copy "$SRC" "$TARGET_DEST" --transfers "$TRANSFERS" --checkers "$CHECKERS" --stats=5s --stats-one-line --log-level INFO
		#--progress
    else
        MSG="❌ BŁĄD: Nieobsługiwany typ: $TYPE"
        echo "$MSG"
        bash /scripts/notify-discord.sh "$MSG"
        exit 1
    fi

    if [ $? -ne 0 ]; then
        MSG="❌ BŁĄD: Backup $JOB_NAME nie powiódł się dla źródła $SRC"
        echo "$MSG"
        bash /scripts/notify-discord.sh "$MSG"
        exit 1
    fi
done

# 📜 HISTORIA BACKUPÓW (jq)
jq ". += [{
  \"job\": \"$JOB_NAME\",
  \"status\": \"OK\",
  \"time\": \"$(date)\",
  \"sources\": $(printf '%s\n' "${SOURCES[@]}" | jq -R . | jq -s .)
}]" /state/history.json > /state/history.tmp

mv /state/history.tmp /state/history.json

# 🔔 Powiadomienie końcowe
MSG="✅ Backup $JOB_NAME zakończony sukcesem."
echo "$MSG"
[ "$NOTIFY_LEVEL" -ge 1 ] && bash /scripts/notify-discord.sh "$MSG"

exit 0
