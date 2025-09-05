#!/bin/bash

limit=$((365)) # pi(364) = (13,13) ultima coppia di Cantor accettata
# infatti 13->[195, 210[, quindi ogni cantor_x > 13 => j >= 200
iff_opt=("$((1/3))" "0.4" "0.5")
iff_dir_names=("33" "40" "50")
len_opt=("10" "15" "20" "25" "30")
res_mode=("fluted" "vampire_fl_prepro" "vampire")
vars_offset=2
pred_num_offset=1
time_limit=300

version_check=$(vampire --show_options on)

if [[ $version_check == *"fluted_gen"* ]]; then
  echo "Modalità fluted_gen disponibile."
else
  echo "Modalità fluted_gen non disponibile. Assicurati di avere la versione corretta di Vampire."
  exit 1
fi

if [[ $# -ne 4 ]]; then
  echo "Usage: $0 <iff> <cantor> <lex> <seed>"
  exit 1
fi

iff_idx="$1"
cantor="$2"
lex_offset="$3"
seed="$4"

# Controlla che tutti gli argomenti siano numerici
if ! [[ "$iff_idx" =~ ^[0-9]+$ && "$cantor" =~ ^[0-9]+$ && "$lex_offset" =~ ^[0-9]+$ && "$seed" =~ ^[0-9]+$ ]]; then
  echo "Errore: tutti gli argomenti devono essere numerici."
  exit 1
fi


if (( iff_idx >= ${#iff_opt[@]} )); then
  echo "unexisting iff option"
  exit 1
fi

if (( cantor >= limit )); then
  echo "unexisting cantor option"
  exit 1
fi

if (( lex_offset >= 15 )); then
  echo "unexisting lex offset"
  exit 1
fi

cantor_couple=$(./cantor_couple $cantor)

cantor_x=${cantor_couple%,*}    # Rimuove tutto dalla prima virgola in poi
cantor_y=${cantor_couple#*,}    # Rimuove tutto fino alla prima virgola inclusa

if (( cantor_x > 13 || cantor_y > 13 )); then
  echo "unexisting cantor option"
  exit 1
fi

lex=$(($cantor_x * 15 + $lex_offset))
if (( lex >= 200 )); then
  echo "unexisting lex option"
  exit 1
fi

lex_triplet=$(./lexicograph_3d $lex)
lex_x=${lex_triplet%%,*}        # Rimuove tutto dalla prima virgola in poi
temp=${lex_triplet#*,}                  # Rimuove tutto fino alla prima virgola
lex_y=${temp%,*}                        # Dalla stringa rimanente, prende fino alla prossima virgola
lex_z=${lex_triplet##*,}        # Rimuove tutto fino all'ultima virgola


echo "Cantor: x=$cantor_x, y=$cantor_y | Converted Cantor: x=$lex| Lexicograph: x=$lex_x, y=$lex_y, z=$lex_z"
echo "($lex_x,$lex_y,$lex_z,$cantor_y)"
iff="${iff_opt[$iff_idx]}"
iff_dir_name="${iff_dir_names[$iff_idx]}"

iff_dir=iff-$iff_dir_name
var_dir=$iff_dir/var-$(($cantor_y + $vars_offset))
res_file="$var_dir/res-$lex.csv"
echo "Results file: $res_file"
echo "----------------------------------------"

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
    echo "Output:"
    echo "$output"
    if [[ $output == *"Time limit reached!"* ]]; then
      results+=","
      results+=$(($time_limit*1000))
      echo "Time limit reached, results: $results"
      res_obtained=true
      if [[ $mode == "vampire_fl_prepro" ]]; then
        hybrid_failed=true
      fi
      break
    fi
    if [[ $? -ne 0 ]] || ! [[ $output =~ ^[0-9]+$ ]]; then
      results+=","
      results+=$(($time_limit*1000 + 30000))
      echo "Errore nell'esecuzione di vampire: $output"
      echo "Results: $results"
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
      echo "Output maggiore di 30000: $output"
      echo "Results: $results"
      res_obtained=true
      break
    fi
    partial_result=$(($partial_result + $output))
    echo "Partial result: $partial_result"
  done
  if [[ $res_obtained == false ]]; then
    results+=","
    results+=$(($partial_result / 5))
    echo "risultato parziale: $partial_result"
  fi
done
echo "$seed$results"