#!/bin/bash

state_file="saved_state"
iff_dir="iff-33"
vars_offset=2
limit=365

for ((cantor_idx=0; cantor_idx<limit; cantor_idx++)); do
  cantor_couple=$(./cantor_couple $cantor_idx)
  cantor_x=${cantor_couple%,*}
  cantor_y=${cantor_couple#*,}
  if (( cantor_x > 13 || cantor_y > 13 )); then
    continue
  fi
  var_dir="$iff_dir/var-$(($cantor_y + $vars_offset))"
  for ((lex_offset=0; lex_offset<15; lex_offset++)); do
    j=$(($cantor_x * 15 + $lex_offset))
    if (( j >= 200 )); then
      continue
    fi
    res_file="$var_dir/res-$j.csv"
    if [[ ! -f "$res_file" ]]; then
      echo "0,$cantor_idx,$lex_offset" > "$state_file"
      echo "Stato ripristinato: 0,$cantor_idx,$lex_offset"
      exit 0
    fi
  done
done

echo "Tutti i file res-Y.csv esistono già. Nessun ripristino necessario."
exit 0