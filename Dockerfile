# Używamy oficjalnego obrazu rclone jako bazy
FROM rclone/rclone:latest

# Instalujemy bash i curl (dos2unix już nie potrzebujemy, ale można go zostawić na wszelki wypadek)
RUN apk update && apk add --no-cache curl bash jq yq

# Kopiujemy nasz harmonogram zadań (cron) z projektu do systemu kontenera
#COPY crontab /etc/crontabs/root

# Zmieniamy powłokę na bash
SHELL ["/bin/bash", "-c"]

# Uruchamiamy demona cron na pierwszym planie (to utrzyma kontener przy życiu)
#ENTRYPOINT ["crond", "-f", "-d", "8"]

# Zapisujemy zmienne do pliku systemowego, a potem uruchamiamy crona
#ENTRYPOINT ["/bin/bash", "-c", "env > /etc/environment && crond -f -d 8 && /scripts/cron-watcher.sh"]
ENTRYPOINT ["/bin/bash", "-c", "env > /etc/environment; crond -f -d 8 & /scripts/cron-watcher.sh"]

COPY scripts/ /scripts/
# Nadanie uprawnień wszystkim plikom .sh w katalogu scripts
RUN chmod +x /scripts/*.sh
