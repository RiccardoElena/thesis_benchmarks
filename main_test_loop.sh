#!/bin/bash

# Variabili di configurazione
gen_mode=false
restrict_mode=false
limit=$((365)) # pi(364) = (13,13) ultima coppia di Cantor accettata
# infatti 13->[195, 210[, quindi ogni cantor_x > 13 => j >= 200
iff_opt=("$((1/3))" "0.4" "0.5")
iff_dir_names=("33" "40" "50")
len_opt=("10" "15" "20" "25" "30")
res_mode=( "fluted" "vampire_fl_prepro" "vampire")
vars_offset=2
pred_num_offset=1
time_limit=300

# Controllo della versione di Vampire

version_check=$(vampire --show_options on)

if [[ $version_check == *"fluted_gen"* ]]; then
  echo "Modalità fluted_gen disponibile."
else
  echo "Modalità fluted_gen non disponibile. Assicurati di avere la versione corretta di Vampire."
  exit 1
fi

# Recupero lo stato salvato
state_file="saved_state"
saved_line=""
saved_iff=0
saved_cantor=0
saved_lex_offset=0
if [[ -f "$state_file" ]]; then
  read -r saved_line < "$state_file"
  if [[ -n "$saved_line" ]]; then
    saved_iff=${saved_line%%,*}  # Estrae il primo valore prima della prima virgola
    temp=${saved_line#*,}  # Rimuove il primo valore e la prima virgola
    saved_cantor=${temp%%,*}  # Estrae il secondo valore (prima della prossima virgola)
    saved_lex_offset=${saved_line##*,}  # Estrae il terzo valore dopo l'ultima virgola

  fi
else
  touch "$state_file"
fi

echo "Saved iff: $saved_iff"
echo "Saved cantor: $saved_cantor"
echo "Saved lex offset: $saved_lex_offset"


if ! [[ "$saved_iff" =~ ^[0-9]+$ && "$saved_cantor" =~ ^[0-9]+$ && "$saved_lex_offset" =~ ^[0-9]+$ ]]; then
  echo "corrupted state"
  exit 1
fi

if (( saved_iff >= ${#iff_opt[@]} )); then
  echo "unexisting iff option"
  exit 1
fi

if (( saved_cantor >= limit )); then
  echo "unexisting cantor option"
  exit 1
fi

if (( saved_lex_offset >= 15 )); then
  echo "unexisting lex offset"
  exit 1
fi

# Gestione della flag -g

while [[ $# -gt 0 ]]; do
    case $1 in
        -g)
            gen_mode=true
            shift
            ;;
        -r)
            restrict_mode=true
            shift
            ;;
        *)
            echo "Uso: $0 [-g]"
            echo "  -g: abilita modalità debug/verbose"
            exit 1
            ;;
    esac
done

# Inizio main loop

for i in "${!iff_opt[@]}"; do
  if (( i < saved_iff )); then
    continue
  fi
  iff="${iff_opt[i]}"
  iff_dir_name="${iff_dir_names[i]}"
  
  iff_dir=iff-$iff_dir_name

  if [[ -d "$iff_dir" ]]; then
    echo "Directory $iff_dir esiste già"
  else 
    echo "Creazione della directory $iff_dir"
    mkdir "$iff_dir"
  fi

  # Inizio ciclo per le coppie di Cantor
  for ((cantor_idx=saved_cantor; cantor_idx<limit; cantor_idx++)) do
    saved_cantor=0
    cantor_couple=$(./cantor_couple $cantor_idx)
    
    # Dividi a in x e y usando l'espansione dei parametri bash
    cantor_x=${cantor_couple%,*}    # Rimuove tutto dalla prima virgola in poi
    cantor_y=${cantor_couple#*,}    # Rimuove tutto fino alla prima virgola inclusa

    if (( cantor_x > 13 || cantor_y > 13 )); then
      continue
    fi
    var_dir=$iff_dir/var-$(($cantor_y + $vars_offset))
    if [[ -d "$var_dir" ]]; then
      echo "Directory $var_dir esiste già"
    else 
      echo "Creazione della directory $var_dir"
      mkdir -p "$var_dir"
    fi

    # Inizio ciclo per i valori di offset di lexicograph
    for ((lex_offset=saved_lex_offset; lex_offset<15; lex_offset++)) do
      saved_lex_offset=0
      j=$(($cantor_x * 15 + $lex_offset))

      # In restrict mode, skip certain conditions

      echo $cantor_y " " $j
      if (( restrict_mode == true && (j>=75 || cantor_y > 7) )); then
        echo "Checking restricted mode"
        if [[ ! -f "skipped" ]]; then
          touch "skipped"
        fi
        # Questo if è fatto in modo per chiudere a numero tondo 75 almeno var-3
        echo $cantor_y " " $j
        echo "SKIPPING FOR RESTRICTED MODE"
        echo "$i,$cantor_idx,$lex_offset" >> "skipped"
        continue
      fi
      if (( j >= 200 )); then
        continue
      fi

      file="$var_dir/lexicograph-$j.csv"
      res_file="$var_dir/res-$j.csv"

      if [[ $gen_mode == true && ! -f "$file" ]]; then
        echo "File $file non trovato, creazione..."
        echo "Seed,Fluted,Hibrid,Vampire" > $file
      elif [[ ! -f "$res_file" ]]; then
        echo "File $res_file non trovato, creazione..."
        echo "Seed,Fluted,Hibrid,Vampire" > $res_file
      fi

      lex_triplet=$(./lexicograph_3d $j)
      lex_x=${lex_triplet%%,*}        # Rimuove tutto dalla prima virgola in poi
      temp=${lex_triplet#*,}                  # Rimuove tutto fino alla prima virgola
      lex_y=${temp%,*}                        # Dalla stringa rimanente, prende fino alla prossima virgola
      lex_z=${lex_triplet##*,}        # Rimuove tutto fino all'ultima virgola

      echo "Cantor: x=$cantor_x, y=$cantor_y | Converted Cantor: x=$j| Lexicograph: x=$lex_x, y=$lex_y, z=$lex_z"
      echo "($lex_x,$lex_y,$lex_z,$cantor_y)"
      echo "Results file: $res_file"
      echo "----------------------------------------"
      
      # Salva lo stato corrente
      echo "$i,$cantor_idx,$lex_offset" > "$state_file"

      # Normalizzazione dei valori
      unitsNum=$(($lex_x*3 +1))
      maxArity=$(($cantor_y + $vars_offset))
      maxLen=${len_opt[$lex_y]}
      predNum=$(($lex_z + $pred_num_offset))
      if [[ $iff -eq 33 ]]; then
        iff_prob=0
      else
        iff_prob=$iff
      fi

      echo "Units: $unitsNum, Max Arity: $maxArity, Max Len: $maxLen, Pred Num: $predNum, Iff: $iff_prob"
      if [[ $gen_mode == true ]]; then
        for ((k=0; k<25; k++)); do
          output=$(echo " " | vampire --mode fluted_gen --gen_mode gen --input_syntax tptp --units_num "$unitsNum" --iff_prob "$iff_prob" --time_limit "$time_limit"s --max_arity "$maxArity" --max_len "$maxLen" --pred_num "$predNum" 2>&1)
          if [[ $? -ne 0 ]]; then
            echo "Errore nell'esecuzione di vampire: $output"
            exit 1
          fi
          echo "$output" >> "$file"
        done
      else
        # Leggi le righe del file (esclusa la prima) ed estrai il seed
        if [[ -f "$file" ]]; then
          tail -n +2 "$file" | while IFS=',' read -r seed vampire fluted hibrid; do
            echo "Seed estratto: $seed"
            results=""  
            hybrid_failed=false
            #fluted_failed=false
            for mode in "${res_mode[@]}"; do
              res_obtained=false
              if [[ $mode == "vampire" && $hybrid_failed == true ]]; then
                echo "Modalità $mode saltata a causa di un fallimento precedente."
                results+=",??"
                continue
              fi
              echo "Esecuzione in modalità: $mode"
              echo "Ora di esecuzione: $(date '+%H:%M:%S')"
              partial_result=0
              for ((t=0; t<5; t++)); do
                output=$(echo " " | vampire --mode fluted_gen --gen_mode "$mode" --input_syntax tptp --units_num "$unitsNum" --iff_prob "$iff" -t "$time_limit"s --max_arity "$maxArity" --max_len "$maxLen" --pred_num "$predNum" --seed "$seed")
                if [[ $output == *"Time limit reached!"* ]]; then
                  results+=","
                  results+=$(($time_limit*1000))
                  res_obtained=true
                  if [[ $mode == "vampire_fl_prepro" ]]; then
                    hybrid_failed=true
                  fi
                  break
                fi
                if [[ $? -ne 0 ]] || ! [[ $output =~ ^[0-9]+$ ]]; then
                  results+=","
                  results+=$(($time_limit*1000 + 30000))
                  res_obtained=true
                  if [[ $mode == "vampire_fl_prepro" ]]; then
                  hybrid_failed=true
                  fi
                 # if [[ $mode == "fluted" ]]; then
                  #  fluted_failed=true
                  #fi
                  break
                fi
                if [[ $output -ge 30000 ]]; then
                  results+=","
                  results+=$(($output))
                  res_obtained=true
                  break
                fi
                partial_result=$(($partial_result + $output))
              done
              if [[ $res_obtained == false ]]; then
                results+=","
                results+=$(($partial_result / 5))
              fi
            done
            echo "$seed$results" >> "$res_file"
          done
        fi
      fi
    done
  done
done
