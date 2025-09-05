#!/bin/bash

# Script per calcolare le medie dei file CSV che iniziano con "res"
# Uso: ./script.sh <cartella_principale> <prefisso_file>
# Esempio: ./script.sh iff-33 res

if [ $# -ne 2 ]; then
    echo "Uso: $0 <cartella_principale> <prefisso_file>"
    echo "Esempio: $0 iff-33 res"
    exit 1
fi

MAIN_DIR="$1"
PREFIX="$2"

# Verifica che la cartella principale esista
if [ ! -d "$MAIN_DIR" ]; then
    echo "Errore: La cartella '$MAIN_DIR' non esiste"
    exit 1
fi

echo "Analizzando la cartella: $MAIN_DIR"
echo "Cercando file che iniziano con: $PREFIX"

# Per ogni sottocartella nella cartella principale
for subdir in "$MAIN_DIR"/*/; do
    if [ -d "$subdir" ]; then
        subdir_name=$(basename "$subdir")
        echo "Processando sottocartella: $subdir_name"
        
        # Nome del file di output delle medie
        avg_file="$subdir/${PREFIX}-avg.csv"
        
        # Flag per sapere se abbiamo già scritto l'header
        header_written=false
        
        # Trova tutti i file che iniziano con il prefisso specificato
        for file in "$subdir"${PREFIX}-*.csv; do
            if [ -f "$file" ]; then
                # Estrai il numero dal nome del file (es: res-15.csv -> 15)
                filename=$(basename "$file" .csv)
                number=$(echo "$filename" | sed "s/^${PREFIX}-//")
                
                if [[ "$number" =~ ^[0-9]+$ ]]; then
                    echo "  Processando file: $(basename "$file") (numero: $number)"
                else
                    echo "  Saltando file: $(basename "$file") (non è un numero valido: $number)"
                    continue
                fi
                
                # Leggi l'header se non è ancora stato scritto
                if [ "$header_written" = false ]; then
                    # Leggi l'header originale e sostituisci la prima colonna con "Lex"
                    original_header=$(head -n 1 "$file")
                    # Rimuovi la prima colonna e aggiungi "Lex" all'inizio
                    new_header="Lex,$(echo "$original_header" | cut -d',' -f2-)"
                    echo "$new_header" > "$avg_file"
                    header_written=true
                fi
                
                # Conta il numero di colonne (escludendo la prima)
                num_cols=$(head -n 1 "$file" | tr ',' '\n' | wc -l)
                data_cols=$((num_cols - 1))
                
                # Calcola le medie delle colonne (saltando l'header e la prima colonna)
                averages=""
                for col in $(seq 2 $num_cols); do
                    # Calcola la media della colonna, saltando l'header
                    avg=$(tail -n +2 "$file" | cut -d',' -f$col | awk '{sum+=$1; count++} END {if(count>0) printf "%.2f", sum/count; else print "0"}')
                    if [ -z "$averages" ]; then
                        averages="$avg"
                    else
                        averages="$averages,$avg"
                    fi
                done
                
                # Scrivi la riga con il numero del file e le medie
                echo "New line $number,$averages"
                echo "$number,$averages" >> "$avg_file"
            fi
        done
        
        if [ -f "$avg_file" ]; then
            echo "  File delle medie creato: $avg_file"
            # Ordina il file per numero (escludendo l'header)
            (head -n 1 "$avg_file"; tail -n +2 "$avg_file" | sort -t',' -k1 -n) > "${avg_file}.tmp" && mv "${avg_file}.tmp" "$avg_file"
        else
            echo "  Nessun file $PREFIX-*.csv trovato in $subdir_name"
        fi
        
        echo ""
    fi
done

echo "Elaborazione completata!"