#!/bin/bash

n=$((14*14))

for ((i=0; i<n; i++))
do
    # a=$(./cantor_couple $i)
    
    # # Dividi a in x e y usando l'espansione dei parametri bash
    # x=${a%,*}    # Rimuove tutto dalla prima virgola in poi
    # y=${a#*,}    # Rimuove tutto fino alla prima virgola inclusa
    
    # echo "x=$x, y=$y"
    ./cantor_couple $i
done