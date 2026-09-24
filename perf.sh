#!/bin/bash

gcc -O2 -Wall -o ./mininloganalyzer_v1b mininloganalyzer_v1b.c
gcc -O2 -Wall -o ./mininloganalyzer_v1 mininloganalyzer_v1.c
gcc -O2 -Wall -o ./mininloganalyzer_v0 mininloganalyzer_v0.c
gcc -O2 -Wall -o ./mininloganalyzer_v2 mininloganalyzer_v2.c

mkdir -p perfs
mkdir -p results

> perfs/perfs_v0.txt
> perfs/perfs_v1.txt
> perfs/perfs_v2.txt
> perfs/perfs_v1b.txt

for i in $(seq 1 10); do
    echo "tour $i"
    { perf stat -e cache-misses,cache-references,instructions,cpu-cycles ./mininloganalyzer_v0 access_1M.log > /dev/null ; } 2>> perfs/perfs_v0.txt
    { perf stat -e cache-misses,cache-references,instructions,cpu-cycles ./mininloganalyzer_v1 access_1M.log > /dev/null ; } 2>> perfs/perfs_v1.txt
    { perf stat -e cache-misses,cache-references,instructions,cpu-cycles ./mininloganalyzer_v1b access_1M.log > /dev/null ; } 2>> perfs/perfs_v1b.txt
    { perf stat -e cache-misses,cache-references,instructions,cpu-cycles ./mininloganalyzer_v2 access_1M.log > /dev/null ; } 2>> perfs/perfs_v2.txt
done

TIME_V0="$(
    grep 'time elapsed' perfs/perfs_v0.txt |
    grep -oE '[0-9]+,[0-9]+' |
    tr ',' '.' |
    awk '{sum += $1; n++} END {print sum/n}'
)"
TIME_V1="$(
    grep 'time elapsed' perfs/perfs_v1.txt |
    grep -oE '[0-9]+,[0-9]+' | tr ',' '.' |
    awk '{sum += $1; n++} END {print sum/n}'
)"
TIME_V1B="$(
    grep 'time elapsed' perfs/perfs_v1b.txt |
    grep -oE '[0-9]+,[0-9]+' |
    tr ',' '.' |
    awk '{sum += $1; n++} END {print sum/n}'
)"
TIME_V2="$(
    grep 'time elapsed' perfs/perfs_v2.txt |
    grep -oE '[0-9]+,[0-9]+'|
    tr ',' '.' |
    awk '{sum += $1; n++} END {print sum/n}'
)"

average_ratio() {
    awk -v numerator="$2" -v denominator="$3" '
        $2 == numerator {
            value = $1
            gsub(/\./, "", value)
            if (value ~ /^[0-9]+$/) numerator_values[++n] = value
        }
        $2 == denominator {
            value = $1
            gsub(/\./, "", value)
            if (value ~ /^[0-9]+$/) denominator_values[++m] = value
        }
        END {
            count = (n < m) ? n : m
            for (i = 1; i <= count; i++) sum += numerator_values[i] / denominator_values[i]
            if (count > 0) printf "%.2f", sum / count
        }
    ' "$1"
}

IPC_V0="$(average_ratio perfs/perfs_v0.txt cpu_core/instructions/u cpu_core/cpu-cycles/u)"
IPC_V1="$(average_ratio perfs/perfs_v1.txt cpu_core/instructions/u cpu_core/cpu-cycles/u)"
IPC_V1B="$(average_ratio perfs/perfs_v1b.txt cpu_core/instructions/u cpu_core/cpu-cycles/u)"
IPC_V2="$(average_ratio perfs/perfs_v2.txt cpu_core/instructions/u cpu_core/cpu-cycles/u)"

CM_V0="$(average_ratio perfs/perfs_v0.txt cpu_core/cache-misses/u cpu_core/cache-references/u | awk '{printf "%.2f%%", 100 * $1}')"
CM_V1="$(average_ratio perfs/perfs_v1.txt cpu_core/cache-misses/u cpu_core/cache-references/u | awk '{printf "%.2f%%", 100 * $1}')"
CM_V1B="$(average_ratio perfs/perfs_v1b.txt cpu_core/cache-misses/u cpu_core/cache-references/u | awk '{printf "%.2f%%", 100 * $1}')"
CM_V2="$(average_ratio perfs/perfs_v2.txt cpu_core/cache-misses/u cpu_core/cache-references/u | awk '{printf "%.2f%%", 100 * $1}')"


printf '%b\n' "
Mesure|v0|v1|v1b|v2|\n
Real Time|${TIME_V0}|${TIME_V1}|${TIME_V1B}|${TIME_V2}|\n
IPC|${IPC_V0}|${IPC_V1}|${IPC_V1B}|${IPC_V2}|\n
Cache-miss rate|${CM_V0}|${CM_V1}|${CM_V1B}|${CM_V2}\n" | column -t -s '|' > results/perfs.txt

cat results/perfs.txt