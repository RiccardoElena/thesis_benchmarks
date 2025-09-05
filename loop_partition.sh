#!/bin/bash

limit=$((393)) # pi(392) = (13,14) ultima coppia di Cantor accettata
# infatti 13->[195, 210[, quindi ogni cantor_x > 13 => j >= 200

for ((i=0; i<limit; i++))
do
    cantor_couple=$(./cantor_couple $i)
    
    # Dividi a in x e y usando l'espansione dei parametri bash
    cantor_x=${cantor_couple%,*}    # Rimuove tutto dalla prima virgola in poi
    cantor_y=${cantor_couple#*,}    # Rimuove tutto fino alla prima virgola inclusa
    if (( cantor_x > 14 || cantor_y > 14 )); then
      continue
    fi
    for ((j=cantor_x *15; j<(cantor_x + 1)*15; j++))
    do
    if (( j >= 200 )); then
      continue
    fi
    lexicograph_triplet=$(./lexicograph_3d $j)
    lexicograph_x=${lexicograph_triplet%%,*}        # Rimuove tutto dalla prima virgola in poi
    temp=${lexicograph_triplet#*,}                  # Rimuove tutto fino alla prima virgola
    lexicograph_y=${temp%,*}                        # Dalla stringa rimanente, prende fino alla prossima virgola
    lexicograph_z=${lexicograph_triplet##*,}        # Rimuove tutto fino all'ultima virgola

    echo "Cantor: x=$cantor_x, y=$cantor_y | Converted Cantor: x=$j| Lexicograph: x=$lexicograph_x, y=$lexicograph_y, z=$lexicograph_z"
    echo "($lexicograph_x,$lexicograph_y,$lexicograph_z,$cantor_y)"
    echo "----------------------------------------"
    done
done