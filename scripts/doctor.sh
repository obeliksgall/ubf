#!/bin/bash

echo "UBF DOCTOR"
echo "=========="

command -v rclone >/dev/null && echo "rclone OK" || echo "rclone MISSING"

[ -f /config/rclone/rclone.conf ] && echo "config OK" || echo "config MISSING"
[ -d /jobs ] && echo "jobs OK" || echo "jobs MISSING"
[ -d /logs ] && echo "logs OK" || echo "logs MISSING"
[ -d /state ] && echo "state OK" || echo "state MISSING"
[ -d /lock ] && echo "lock OK" || echo "lock MISSING"

# Sprawdzenie czy w folderze lock znajdują się jakiekolwiek pliki blokad
if ls /lock/*.lock 1> /dev/null 2>&1; then
    echo "LOCKS ACTIVE (znaleziono pliki blokad w /lock/)"
else
    echo "LOCK FREE"
fi
