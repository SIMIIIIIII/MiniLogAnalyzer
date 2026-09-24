#!/bin/bash

echo " " > times.txt

for i in $(seq 1 10); do
    { time ./mininloganalyzer access.log > /dev/null ; } 2>> times.txt
done

echo "Moyennes: "
grep '^real' times.txt | grep -oE '[0-9]+,[0-9]+s' | tr -d 's' | tr ',' '.' | awk '{sum += $1; n++} END {print "real :", sum/n}'
grep '^user' times.txt | grep -oE '[0-9]+,[0-9]+s' | tr -d 's' | tr ',' '.' | awk '{sum += $1; n++} END {print "user :", sum/n}'
grep '^sys' times.txt | grep -oE '[0-9]+,[0-9]+s' | tr -d 's' | tr ',' '.' | awk '{sum += $1; n++} END {print "sys :", sum/n}'