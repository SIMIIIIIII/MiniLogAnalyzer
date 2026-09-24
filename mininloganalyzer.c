#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LINE 2048
#define MAX_CODE 600

static int cmp_long(const void *a, const void *b) {
    long la = *(const long *)a, lb = *(const long *)b;
    return (la > lb) - (la < lb);
}


static long percentile(long *sorted, long n, double p) {
    if (n == 0) return 0;
    long idx = (long)(p / 100.0 * (n - 1));
    return sorted[idx];
}

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
    long capacity = 1024, n_sizes = 0;
    long *sizes = malloc(capacity * sizeof(long));

    if (sizes == NULL) {
        fprintf(stderr, "malloc a echoue\n");
        return 1;
    }

    while (fgets(line, MAX_LINE, f) != NULL) {
        total_lines++;
        char *quote = strrchr(line, '"');

        if (quote == NULL) continue;
        int code = 0; long size = 0;

        if (sscanf(quote + 1, " %d %ld", &code, &size) == 2) {
            if (code >= 0 && code < MAX_CODE) counts[code]++;
            if (n_sizes == capacity) {
                capacity *= 2;
                // tableau dynamique : on double
                long *tmp = realloc(sizes, capacity * sizeof(long));
                if (tmp == NULL) {
                    fprintf(stderr, "realloc a echoue\n");
                    return 1;
                }
                sizes = tmp;
            }
            sizes[n_sizes++] = size;
        }
    }

    fclose(f);

    printf("Lignes traitees : %ld\n", total_lines);

    for (int code = 100; code < MAX_CODE; code++){
        if (counts[code] > 0) printf(" code %d : %d\n", code, counts[code]);
    }

    if (n_sizes > 0) {
        qsort(sizes, n_sizes, sizeof(long), cmp_long);

        // tri necessaire pour median/percentiles
        double sum = 0;
        for (long i = 0; i < n_sizes; i++) sum += sizes[i];
        printf("\nTailles de reponse (n=%ld octets) :\n", n_sizes);
        printf(" min: %ld\n", sizes[0]);
        printf(" max: %ld\n", sizes[n_sizes - 1]);
        printf(" moyenne : %.1f\n", sum / n_sizes);
        printf(" mediane : %ld\n", percentile(sizes, n_sizes, 50));
        printf(" p95: %ld\n", percentile(sizes, n_sizes, 95));
    }
    free(sizes);
    return 0;
}