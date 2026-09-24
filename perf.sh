#!/bin/bash

gcc -O2 -Wall -o ./mininloganalyzer_v1b mininloganalyzer_v1b.c
gcc -O2 -Wall -o ./mininloganalyzer_v1 mininloganalyzer_v1.c
gcc -O2 -Wall -o ./mininloganalyzer_v0 mininloganalyzer_v0.c
gcc -O2 -Wall -o ./mininloganalyzer_v2 mininloganalyzer_v2.c

mkdir perfs
mkdir results

> perfs/perfs_v0.txt
> perfs/perfs_v1.txt
> perfs/perfs_v2.txt
> perfs/perfs_v1b.txt

for i in $(seq 1 10); do
    echo "tour $i"
    { perf stat ./mininloganalyzer_v0 access_1M.log > /dev/null ; } 2>> perfs/perfs_v0.txt
    { perf stat ./mininloganalyzer_v1 access_1M.log > /dev/null ; } 2>> perfs/perfs_v1.txt
    { perf stat ./mininloganalyzer_v1b access_1M.log > /dev/null ; } 2>> perfs/perfs_v1b.txt
    { perf stat ./mininloganalyzer_v2 access_1M.log > /dev/null ; } 2>> perfs/perfs_v2.txt
done

TIME_V0="$(grep 'time elapsed' perfs/perfs_v0.txt | grep -oE '[0-9]+,[0-9]+' | tr ',' '.' | awk '{sum += $1; n++} END {print sum/n}')"
TIME_V1="$(grep 'time elapsed' perfs/perfs_v1.txt | grep -oE '[0-9]+,[0-9]+' | tr ',' '.' | awk '{sum += $1; n++} END {print sum/n}')"
TIME_V1B="$(grep 'time elapsed' perfs/perfs_v1b.txt | grep -oE '[0-9]+,[0-9]+' | tr ',' '.' | awk '{sum += $1; n++} END {print sum/n}')"
TIME_V2="$(grep 'time elapsed' perfs/perfs_v2.txt | grep -oE '[0-9]+,[0-9]+' | tr ',' '.' | awk '{sum += $1; n++} END {print sum/n}')"

IPC_V0="$(grep 'cpu_core/instructions/u' perfs/perfs_v0.txt | awk '{print $1}' | tr -d '.' | awk '{sum += $1; n++} END {printf "%.0f\n", sum/n}')"
IPC_V1="$(grep 'cpu_core/instructions/u' perfs/perfs_v1.txt | awk '{print $1}' | tr -d '.' | awk '{sum += $1; n++} END {printf "%.0f\n", sum/n}')"
IPC_V1B="$(grep 'cpu_core/instructions/u' perfs/perfs_v1b.txt | awk '{print $1}' | tr -d '.' | awk '{sum += $1; n++} END {printf "%.0f\n", sum/n}')"
IPC_V2="$(grep 'cpu_core/instructions/u' perfs/perfs_v2.txt | awk '{print $1}' | tr -d '.' | awk '{sum += $1; n++} END {printf "%.0f\n", sum/n}')"

CM_V0="$(grep 'cpu_core/branch-misses/u' perfs/perfs_v0.txt | awk '{print $1}' | tr -d '.' | awk '{sum += $1; n++} END {printf "%.0f\n", sum/n}')"
CM_V1="$(grep 'cpu_core/branch-misses/u' perfs/perfs_v1.txt | awk '{print $1}' | tr -d '.' | awk '{sum += $1; n++} END {printf "%.0f\n", sum/n}')"
CM_V1B="$(grep 'cpu_core/branch-misses/u' perfs/perfs_v1b.txt | awk '{print $1}' | tr -d '.' | awk '{sum += $1; n++} END {printf "%.0f\n", sum/n}')"
CM_V2="$(grep 'cpu_core/branch-misses/u' perfs/perfs_v2.txt | awk '{print $1}' | tr -d '.' | awk '{sum += $1; n++} END {printf "%.0f\n", sum/n}')"

clear

printf "
Mesure|v0|v1|v1b|v2|\n
Real Time|${TIME_V0}|${TIME_V1}|${TIME_V1B}|${TIME_V2}|\n
IPC|${IPC_V0}|${IPC_V1}|${IPC_V1B}|${IPC_V2}|\n
Cache-misses|${CM_V0}|${CM_V1}|${CM_V1B}|${CM_V2}\n" | column -t -s '|' > results/perfs2.txt

cat results/perfs.txt