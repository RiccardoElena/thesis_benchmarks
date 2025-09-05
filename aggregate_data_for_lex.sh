#!/bin/bash

# Script per creare confronto orizzontale dei file res-avg.csv
# Uso: ./script.sh <cartella_principale>
# Esempio: ./script.sh iff-33

if [ $# -ne 1 ]; then
    echo "Uso: $0 <cartella_principale>"
    echo "Esempio: $0 iff-33"
    exit 1
fi

MAIN_DIR="$1"
AVG_FILE="res-avg.csv"

# Verifica che la cartella principale esista
if [ ! -d "$MAIN_DIR" ]; then
    echo "Errore: La cartella '$MAIN_DIR' non esiste"
    exit 1
fi

echo "Analizzando la cartella: $MAIN_DIR"
echo "Cercando file: $AVG_FILE"

# Array associativo per tenere traccia di tutti i numeri trovati
declare -A all_numbers
# Array associativo per tenere traccia degli header (dovrebbero essere uguali)
header_line=""

# Prima passata: raccoglie tutti i numeri possibili e l'header
echo "Prima passata: raccolta numeri e header..."
for subdir in "$MAIN_DIR"/*/; do
    if [ -d "$subdir" ]; then
        avg_file="$subdir$AVG_FILE"
        if [ -f "$avg_file" ]; then
            subdir_name=$(basename "$subdir")
            echo "  Trovato $AVG_FILE in: $subdir_name"
            
            # Salva l'header se non l'abbiamo ancora fatto
            if [ -z "$header_line" ]; then
                header_line=$(head -n 1 "$avg_file")
                # Sostituisce "Lex" con "Var" nell'header
                header_line=$(echo "$header_line" | sed 's/^Lex,/Var,/')
            fi
            
            # Raccoglie tutti i numeri (prima colonna, saltando l'header)
            while IFS=',' read -r number rest; do
                if [[ "$number" =~ ^[0-9]+$ ]]; then  # Controlla che sia un numero
                    all_numbers[$number]=1
                fi
            done < <(tail -n +2 "$avg_file")
        fi
    fi
done

if [ -z "$header_line" ]; then
    echo "Errore: Nessun file $AVG_FILE trovato nelle sottocartelle"
    exit 1
fi

echo "Header trovato: $header_line"
echo "Numeri trovati: $(echo ${!all_numbers[@]} | tr ' ' ',')"

# Per ogni numero trovato, crea un file separato
for number in $(printf '%s\n' "${!all_numbers[@]}" | sort -n); do
    output_file="$MAIN_DIR/res-avg-$number.csv"
    echo "Creando file: $output_file"
    
    # Scrivi l'header
    echo "$header_line" > "$output_file"
    
    # Seconda passata: per ogni sottocartella, cerca la riga con questo numero
    for subdir in "$MAIN_DIR"/*/; do
        if [ -d "$subdir" ]; then
            avg_file="$subdir$AVG_FILE"
            if [ -f "$avg_file" ]; then
                subdir_name=$(basename "$subdir")
                # Estrai il numero dalla sottocartella (es: var-2 -> 2)
                var_number=$(echo "$subdir_name" | sed 's/.*-//')
                
                # Cerca la riga con il numero specificato
                line_found=$(tail -n +2 "$avg_file" | grep "^$number,")
                
                if [ -n "$line_found" ]; then
                    # Sostituisce il primo campo (numero) con il numero della variabile
                    new_line="$var_number,$(echo "$line_found" | cut -d',' -f2-)"
                    echo "$new_line" >> "$output_file"
                    echo "  Aggiunta riga da $subdir_name: $new_line"
                else
                    echo "  Numero $number non trovato in $subdir_name"
                fi
            fi
        fi
    done
    
    # Ordina il file per numero di variabile (escludendo l'header)
    if [ -f "$output_file" ]; then
        (head -n 1 "$output_file"; tail -n +2 "$output_file" | sort -t',' -k1 -n) > "${output_file}.tmp" && mv "${output_file}.tmp" "$output_file"
        echo "  File $output_file completato e ordinato"
    fi
    
    echo ""
done

echo "Elaborazione completata!"
echo "File creati nella cartella: $MAIN_DIR"
ls -la "$MAIN_DIR"/res-avg-*.csv 2>/dev/null || echo "Nessun file di output creato"