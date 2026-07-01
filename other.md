## **Konsola kontenera**

```
sudo docker exec -it ubf sh
```

## **Instalacja curl**

W kontenerze:

```
apk add curl
```

---

## **Instalacja dos2unix**

```
apk add dos2unix
```

---

## **Konwersja pliku do formatu Unix**

```
dos2unix /scripts/run-all.sh
dos2unix /scripts/run-job.sh
dos2unix /scripts/doctor.sh
dos2unix /scripts/status.sh
```

---

## **Sprawdzenie niewidocznych znaków (CRLF)**

```
cat -A /scripts/run-all.sh
```

Poprawny plik:

```
$
```

Zły plik:

```
^M$
```

---

## **Uruchamianie jobów z NAS (host)**

Zawsze przez Docker:

```
sudo docker exec ubf sh /scripts/run-job.sh test
```

---

## **Sprawdzenie lock**

```
ls /volume1/docker/ubf/lock
```

---

## **Sprawdzenie logów**

```
ls /volume1/docker/ubf/logs/current
```

---

## **Sprawdzenie historii**

```
sudo docker exec ubf sh /scripts/status.sh
```

---