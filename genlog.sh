#!/bin/bash
# genere N lignes de log synthetiques dans access.log

N=${1:-5000000}
CODES=(200 200 200 200 404 500)
> access.log
for ((i=0; i<N; i++)); do
code=${CODES[$((RANDOM % 6))]}
echo "203.0.113.$((RANDOM % 255)) - - [22/Sep/2026:10:15:0$((i % 6))] \"GET /page$((i %
50)).html HTTP/1.1\" $code $((RANDOM % 5000))" >> access.log
done