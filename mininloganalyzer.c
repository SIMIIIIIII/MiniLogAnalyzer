// mininloganalyzer.c -- v0 : version naive et sequentielle
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#define MAX_LINE 2048
#define MAX_CODE 600


int main(int argc, char *argv[]) {
    if (argc != 2) {
        fprintf(stderr, "usage: %s <fichier.log>\n", argv[0]);
        return 1;
    }
    
    FILE *f = fopen(argv[1], "r");
    if (f == NULL) {
        perror("fopen");
        return 1;
    }

    int counts[MAX_CODE] = {0};
    long total_lines = 0;
    char line[MAX_LINE];

    // counts[code] = nombre de lignes avec ce code
    while (fgets(line, MAX_LINE, f) != NULL) {
        total_lines++;
        char *quote = strrchr(line, '"');

        // dernier '"' de la ligne
        if (quote == NULL) continue;
        int code = 0;

        if (sscanf(quote + 1, " %d", &code) == 1) {
        if (code >= 0 && code < MAX_CODE) {
        counts[code]++;
        }
        }
    }

    fclose(f);

    printf("Lignes traitees : %ld\n", total_lines);
    for (int code = 100; code < MAX_CODE; code++) {
        if (counts[code] > 0) {
            printf(" code %d : %d\n", code, counts[code]);
        }
    }
    return 0;
}