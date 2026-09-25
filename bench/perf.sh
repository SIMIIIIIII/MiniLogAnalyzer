#!/bin/bash

make clean >> /dev/null
make all

mkdir -p perfs
mkdir -p results

> perfs/perfs_v0.txt
> perfs/perfs_v1.txt
> perfs/perfs_v2.txt
> perfs/perfs_v1b.txt
> perfs/perfs_v3_1.txt
> perfs/perfs_v3_2.txt
> perfs/perfs_v3_4.txt
> perfs/perfs_v3_8.txt
> perfs/perfs_v4.txt

for i in $(seq 1 10); do
    echo "Round $i"
    { perf stat -e cache-misses,cache-references,instructions,cpu-cycles ./mininloganalyzer_v0 datas/access_1M.log > /dev/null ; } 2>> perfs/perfs_v0.txt
    { perf stat -e cache-misses,cache-references,instructions,cpu-cycles ./mininloganalyzer_v1 datas/access_1M.log > /dev/null ; } 2>> perfs/perfs_v1.txt
    { perf stat -e cache-misses,cache-references,instructions,cpu-cycles ./mininloganalyzer_v1b datas/access_1M.log > /dev/null ; } 2>> perfs/perfs_v1b.txt
    { perf stat -e cache-misses,cache-references,instructions,cpu-cycles ./mininloganalyzer_v2 datas/access_1M.log > /dev/null ; } 2>> perfs/perfs_v2.txt
    { perf stat -e cache-misses,cache-references,instructions,cpu-cycles ./mininloganalyzer_v3 datas/access_1M.log 1 > /dev/null ; } 2>> perfs/perfs_v3_1.txt
    { perf stat -e cache-misses,cache-references,instructions,cpu-cycles ./mininloganalyzer_v3 datas/access_1M.log 2 > /dev/null ; } 2>> perfs/perfs_v3_2.txt
    { perf stat -e cache-misses,cache-references,instructions,cpu-cycles ./mininloganalyzer_v3 datas/access_1M.log 4 > /dev/null ; } 2>> perfs/perfs_v3_4.txt
    { perf stat -e cache-misses,cache-references,instructions,cpu-cycles ./mininloganalyzer_v3 datas/access_1M.log 8 > /dev/null ; } 2>> perfs/perfs_v3_8.txt
    { perf stat -e cache-misses,cache-references,instructions,cpu-cycles ./mininloganalyzer_v4 datas/access_1M.log > /dev/null ; } 2>> perfs/perfs_v4.txt
done

average_ratio() {
    awk -v num_pattern="$2" -v den_pattern="$3" '
        # Vérifie si la colonne 2 contient le motif du numérateur
        $2 ~ num_pattern {
            value = $1
            gsub(/\./, "", value)
            gsub(/,/, "", value) # Gère aussi les séparateurs à virgule
            if (value ~ /^[0-9]+$/) numerator_values[++n] = value
        }
        # Vérifie si la colonne 2 contient le motif du dénominateur
        $2 ~ den_pattern {
            value = $1
            gsub(/\./, "", value)
            gsub(/,/, "", value)
            if (value ~ /^[0-9]+$/) denominator_values[++m] = value
        }
        END {
            count = (n < m) ? n : m
            for (i = 1; i <= count; i++) sum += numerator_values[i] / denominator_values[i]
            if (count > 0) printf "%.2f", sum / count
        }
    ' "$1"
}

FILES=(
    "perfs/perfs_v0.txt"
    "perfs/perfs_v1.txt"
    "perfs/perfs_v1b.txt"
    "perfs/perfs_v2.txt"
    "perfs/perfs_v3_1.txt"
    "perfs/perfs_v3_2.txt"
    "perfs/perfs_v3_4.txt"
    "perfs/perfs_v3_8.txt"
    "perfs/perfs_v4.txt"
)

NBR=${#FILES[@]}

TIMES=()
IPC=()
CM=()

for i in $(seq 0 $((NBR - 1))); do
    # Récupération du temps
    t="$(
        grep 'time elapsed' "${FILES[$i]}" |
        grep -oE '[0-9]+[,.][0-9]+' |
        tr ',' '.' |
        awk '{sum += $1; n++} END {if (n>0) printf "%.6f", sum/n; else print "0"}'
    )"
    
    # On passe uniquement le nom générique de l'événement sans "cpu_core/"
    ip="$(average_ratio "${FILES[$i]}" "instructions" "cpu-cycles")"
    c="$(average_ratio "${FILES[$i]}" "cache-misses" "cache-references")"
    
    # Si le résultat de 'c' n'est pas vide, on applique le formatage en %
    if [ -n "$c" ] && [ "$c" != "0.00" ]; then
        c_percent="$(awk -v val="$c" 'BEGIN {printf "%.2f%%", 100 * val}')"
    else
        c_percent="N/A"
    fi

    TIMES+=("$t")
    IPC+=("${ip:-N/A}")
    CM+=("$c_percent")
done


printf '%b\n' "
Mesure|v0|v1|v1b|v2|v3 1t|v3 2t|v3 4t|v3 8t|v4|\n
Real Time|${TIMES[0]}|${TIMES[1]}|${TIMES[2]}|${TIMES[3]}|${TIMES[4]}|${TIMES[5]}|${TIMES[6]}|${TIMES[7]}|${TIMES[8]}|\n
IPC|${IPC[0]}|${IPC[1]}|${IPC[2]}|${IPC[3]}|${IPC[4]}|${IPC[5]}|${IPC[6]}|${IPC[7]}|${IPC[8]}|\n
Cache-miss rate|${CM[0]}|${CM[1]}|${CM[2]}|${CM[3]}|${CM[4]}|${CM[5]}|${CM[6]}|${CM[7]}|${CM[8]}\n
" | column -t -s '|' > results/perfs.txt

make clean >> /dev/null

cat results/perfs.txt