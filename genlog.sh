#!/bin/bash
# genere N lignes de log synthetiques dans access.log

N=${1:-1000000}

> access_1M.log

for ((i=0; i<N; i++)); do
    r=$((RANDOM % 100))
    if   [ $r -lt 95 ]; then code=200
    elif [ $r -lt 99 ]; then code=404
    else                     code=500
    fi

    echo "203.0.113.$((RANDOM % 255)) - - [22/Sep/2026:10:15:0$((i % 6))] \"GET /page$((i %
    50)).html HTTP/1.1\" $code $((RANDOM % 5000))" >> access_1M.log
done