clean:
	rm perf.* mininloganalyzer_v0 mininloganalyzer_v1 mininloganalyzer_v1b mininloganalyzer_v2 mininloganalyzer_v3 mininloganalyzer_v4 2> /dev/null

all:
	gcc -O2 -Wall -o mininloganalyzer_v1b src/mininloganalyzer_v1b.c
	gcc -O2 -Wall -o mininloganalyzer_v1 src/mininloganalyzer_v1.c
	gcc -O2 -Wall -o mininloganalyzer_v0 src/mininloganalyzer_v0.c
	gcc -O2 -Wall -o mininloganalyzer_v2 src/mininloganalyzer_v2.c
	gcc -O2 -Wall -o mininloganalyzer_v3 src/mininloganalyzer_v3.c
	gcc -O2 -Wall -o mininloganalyzer_v4 src/mininloganalyzer_v4.c

v0:
	gcc -O2 -Wall -o mininloganalyzer_v1b src/mininloganalyzer_v1b.c

v1:
	gcc -O2 -Wall -o mininloganalyzer_v1 src/mininloganalyzer_v1.c

v1b:
	gcc -O2 -Wall -o mininloganalyzer_v0 src/mininloganalyzer_v0.c

v2:
	gcc -O2 -Wall -o mininloganalyzer_v2 src/mininloganalyzer_v2.c

v3:
	gcc -O2 -Wall -o mininloganalyzer_v3 src/mininloganalyzer_v3.c

v4:
	gcc -O2 -Wall -o mininloganalyzer_v4 src/mininloganalyzer_v4.c

perf:
	bash bench/perf.sh

	