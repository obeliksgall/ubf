#!/bin/bash

MSG="$1"

if [ -z "$DISCORD_WEBHOOK" ]; then
    echo "Discord webhook not configured"
    exit 0
fi

curl -s -X POST "$DISCORD_WEBHOOK" \
-H "Content-Type: application/json" \
-d "{\"content\":\"$MSG\"}"
