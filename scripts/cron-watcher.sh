#!/bin/bash

INTERVAL_SECONDS=60  # np. co 5 minut

while true; do
    echo "$(date) 🔄 Reload crona (crond -s)"
    crond -s
    sleep "$INTERVAL_SECONDS"
done
