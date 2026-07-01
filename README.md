# 📄 **README.md (final)**

> **UBF — UGREEN Backup Framework** > Lekki, modularny framework backupowy dla UGREEN NAS, oparty o Docker + rclone.  
> Zaprojektowany do niezawodnych backupów lokalnych i chmurowych (Google Drive, OneDrive, crypt).

---

## 🚀 Funkcje

- YAML‑owe joby backupowe  
- backupy szyfrowane (rclone crypt)  
- backupy publiczne (Google Drive / OneDrive)  
- multi‑source (wiele katalogów w jednym jobie)  
- tryby: **sync**, **copy** - cron scheduler w kontenerze  
- powiadomienia Discord  
- lock anty‑duplikacja (flock)  
- logi + historia backupów (JSON)  
- testy odtwarzania (restore test)  
- pełny deploy z GitHub
- w pełni przenośna architektura (ścieżki względne Dockera)

---

## 📦 Struktura projektu

ubf/
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── README.md
├── scripts/
│   ├── run-job.sh
│   ├── run-all.sh
│   ├── doctor.sh
│   ├── status.sh
│   ├── notify-discord.sh
│   └── lib.sh
├── jobs/
│   └── example.yaml
├── config/
│   ├── rclone.conf.example
│   └── README.md
├── logs/
├── state/
└── lock/

---

## ⚙️ Wymagania

- UGREEN NAS z Dockerem  (lub gdzie indziej o ile masz Docker oraz Docker Compose - pamiętaj o pliku .env)
- rclone remotes skonfigurowane (Google Drive / OneDrive / crypt)  
- plik `rclone.conf` (nie ma go w repo)  

---

## 🛠 Instalacja

### 1. Pobierz repo

Skopiuj projekt do wybranego folderu na swoim serwerze NAS i przejdź do niego:

git clone https://github.com/obeliksgall/ubf.git
cd ubf


### 2. Utwórz `.env`

cp .env.example .env
nano .env


### 3. Wgraj rclone.conf

Skopiuj swój istniejący plik konfiguracyjny do folderu config wewnątrz projektu:

cp /ścieżka/do/twojego/rclone.conf ./config/rclone.conf


### 4. Konfiguracja wolumenów danych

W pliku `docker-compose.yaml` systemowe foldery UBF używają ścieżek względnych (`./`). Aby framework miał dostęp do Twoich danych, musisz zmapować odpowiednie wolumeny hosta (np. dyski NAS) do folderu `/data/` w kontenerze.

Przykład w `docker-compose.yaml`:

    volumes:
      # Foldery systemowe UBF
      - ./config:/config/rclone
      - ./scripts:/scripts
      # ...
      # Twoje dyski z danymi (ZMIEŃ WEDŁUG POTRZEB)
      - /volume1:/data/vol1
      - /volume3:/data/vol3


### 5. Zbuduj kontener i utwórz brakujące katalogi

docker compose up -d --build
mkdir logs state lock


---

## 🔍 Test systemu

docker exec ubf bash /scripts/doctor.sh
docker exec ubf bash /scripts/run-job.sh example


---

## 📁 Joby backupowe (YAML)

Ścieżki lokalne źródła (`source`) muszą zawsze odnosić się do punktu montowania wewnątrz kontenera (np. `/data/vol1/...`).

Przykład:

name: example
source:
  - :local:/data/vol1/Send
  - :local:/data/vol3/Projekty
dest: gdrive:/ubf-test
type: sync
crypt: false
retention_days: 0


---

## ▶️ Uruchamianie jobów

### Pojedynczy job

docker exec ubf bash /scripts/run-job.sh example


### Wszystkie joby

docker exec ubf bash /scripts/run-all.sh


---

## ⏰ Cron (harmonogram)

Cron działa **w kontenerze**. Zmienne środowiskowe pobierane są automatycznie przy każdym uruchomieniu.

Plik: `crontab`

0 6 * * 1 /bin/bash /scripts/run-all.sh >> /logs/cron.log 2>&1


---

## 🔐 Restore test (disaster recovery)

docker exec ubf rclone copy ocrypt:/ubf/onedrive /restore-test/onedrive --progress
docker exec ubf rclone check ocrypt:/ubf/onedrive /restore-test/onedrive


---

## 🔐 Restart

docker compose restart ubf
docker restart ubf


---

## 📜 Licencja

MIT

---