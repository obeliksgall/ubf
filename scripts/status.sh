#!/bin/bash

echo "UBF STATUS"
echo "=========="

#tail -n 20 /state/history.json
# Wyświetla 5 ostatnich poprawnie sformatowanych zdarzeń z pliku JSON
jq '.[-5:]' /state/history.json
