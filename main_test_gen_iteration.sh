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

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <iff> <cantor> <lex>"
  exit 1
fi

iff_idx="$1"
cantor="$2"
lex_offset="$3"

# Controlla che tutti gli argomenti siano numerici
if ! [[ "$iff_idx" =~ ^[0-9]+$ && "$cantor" =~ ^[0-9]+$ && "$lex_offset" =~ ^[0-9]+$ ]]; then
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

iff_dir=iff-${iff_dir_name}-new
if [[ ! -d "$iff_dir" ]]; then
  mkdir -p "$iff_dir"
fi
var_dir=$iff_dir/var-$(($cantor_y + $vars_offset))
if [[ ! -d "$var_dir" ]]; then
  mkdir -p "$var_dir"
fi
file="$var_dir/lexicograph-$lex.csv"
echo "Results file: $file"
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

for ((k=0; k<25; k++)); do
  output=$(echo " " | vampire --mode fluted_gen --gen_mode gen --input_syntax tptp --units_num "$unitsNum" --iff_prob "$iff_prob" --time_limit "$time_limit"s --max_arity "$maxArity" --max_len "$maxLen" --pred_num "$predNum" 2>&1)
  if [[ $? -ne 0 ]]; then
    echo "Errore nell'esecuzione di vampire: $output"
    exit 1
  fi
  echo "$output" >> "$file"
done