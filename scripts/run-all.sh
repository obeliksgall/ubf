#!/bin/bash

# Zabezpieczenie: jeśli katalog jest pusty, pętla się nie zepsuje
for job in /jobs/*.yaml; do
    [ -e "$job" ] || continue
    
    name=$(basename "$job" .yaml)
    echo "Uruchamiam zadanie: $name"
    
    # Wywołujemy pojedyncze zadanie używając bash
    bash /scripts/run-job.sh "$name"
done
