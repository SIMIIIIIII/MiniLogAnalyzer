#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <pthread.h>

#define MAX_LINE 2048
#define MAX_CODE 600

typedef struct {
    const char *filename;
    long start_offset, end_offset; // portion [start_offset, end_offset) du fichier
    int counts[MAX_CODE];          // resultats PRIVES a ce thread
    long total_lines;
    pthread_mutex_t *chopsticks;   // tableau PARTAGE entre tous les threads
    long *sizes;                  // buffer PARTAGE, protege par chopsticks
    size_t *size_count;            // index d'ecriture PARTAGE dans sizes
    int id;
    int nthreads;
} thread_arg_t;

static int cmp_long(const void *a, const void *b) {
    long la = *(const long *)a, lb = *(const long *)b;
    return (la > lb) - (la < lb);
}


static long percentile(long *sorted, long n, double p) {
    if (n == 0) return 0;
    long idx = (long)(p / 100.0 * (n - 1));
    return sorted[idx];
}

static int parse_two_ints(const char *s, int *a, long *b) {
    while (*s == ' ') s++;
    if (*s < '0' || *s > '9') return 0;

    long v1 = 0;
    while (*s >= '0' && *s <= '9') {
        v1 = v1 * 10 + (*s - '0');
        s++;
    }

    while (*s == ' ') s++;
    if (*s < '0' || *s > '9') return 0;

    long v2 = 0;
    while (*s >= '0' && *s <= '9') {
        v2 = v2 * 10 + (*s - '0');
        s++;
    }
    *a = (int)v1;
    *b = v2;
    return 1;
}

void *worker(void *arg) {
    thread_arg_t *ta = (thread_arg_t *)arg;
    int left = ta->id;
    int right = (left + 1) % ta->nthreads;

    FILE *f = fopen(ta->filename, "r");
    fseek(f, ta->start_offset, SEEK_SET);

    char line[MAX_LINE];
    long pos = ta->start_offset;
    while (pos < ta->end_offset && fgets(line, MAX_LINE, f) != NULL) {
        pos += (long)strlen(line);
        ta->total_lines++;
        char *quote = strrchr(line, '"');
        if (quote == NULL) continue;
        int code = 0; long size = 0;

        if (left == right) {
            pthread_mutex_lock(&ta->chopsticks[left]);
        }
        else if (left < right) {
            pthread_mutex_lock(&ta->chopsticks[left]);
            pthread_mutex_lock(&ta->chopsticks[right]);
        }
        else {
            pthread_mutex_lock(&ta->chopsticks[right]);
            pthread_mutex_lock(&ta->chopsticks[left]);
        }

        if (parse_two_ints(quote + 1, &code, &size)) {
            if (code >= 0 && code < MAX_CODE) ta->counts[code]++;
            ta->sizes[(*ta->size_count)++] = size;
        }

        pthread_mutex_unlock(&ta->chopsticks[left]);
        if (right != left) pthread_mutex_unlock(&ta->chopsticks[right]);
    }
    fclose(f);
    return NULL;
}

// trouve la position du prochain debut de ligne a partir de offset approx
long align_to_line_start(FILE *f, long approx_offset) {
    if (approx_offset == 0) return 0;
    fseek(f, approx_offset, SEEK_SET);
    char c;
    long pos = approx_offset;
    while ((c = fgetc(f)) != EOF && c != '\n') pos++;
    return pos + 1;
    // juste apres le '\n' trouve
}

long get_size_file(FILE *f) {
    long position_actuelle = ftell(f);
    fseek(f, 0, SEEK_END);
    long taille = ftell(f);
    fseek(f, position_actuelle, SEEK_SET);
    return taille;
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "usage: %s <fichier.log>\n", argv[0]);
        return 1;
    }

    FILE *f = fopen(argv[1], "r");
    if (f == NULL) {
        perror("fopen");
        return 1;
    }

    int nthreads = atoi(argv[2]);

    if (nthreads < 1) return 1;

    long file_size = get_size_file(f);

    pthread_t threads[nthreads];
    thread_arg_t args[nthreads];
    memset(args, 0, sizeof(args)); // VLA : pas d'initialiseur possible a la declaration
    long chunk = file_size / nthreads;

    pthread_mutex_t chopsticks[nthreads];
    for (int i = 0; i < nthreads; i++) pthread_mutex_init(&chopsticks[i], NULL);

    // une taille par ligne au maximum -> borne superieure sure pour l'allocation
    long *sizes = malloc((size_t)(file_size > 0 ? file_size : 1) * sizeof(long));
    size_t size_count = 0;

    for (int i = 0; i < nthreads; i++) {
        args[i].filename = argv[1];
        args[i].start_offset = align_to_line_start(f, i * chunk);
        args[i].end_offset = (i == nthreads - 1) ? file_size : align_to_line_start(f, (i + 1) * chunk);
        args[i].id = i;
        args[i].chopsticks = chopsticks;
        args[i].sizes = sizes;
        args[i].size_count = &size_count;
        args[i].nthreads = nthreads;
        pthread_create(&threads[i], NULL, worker, &args[i]);
    }

    int counts[MAX_CODE] = {0};
    long total_lines = 0;
    for (int i = 0; i < nthreads; i++) {
        pthread_join(threads[i], NULL);
        total_lines += args[i].total_lines;
        for (int c = 0; c < MAX_CODE; c++) counts[c] += args[i].counts[c];
    }

    for (int i = 0; i < nthreads; i++) pthread_mutex_destroy(&chopsticks[i]);

    fclose(f);

    printf("Lignes traitees : %ld\n", total_lines);

    size_t n_sizes = size_count;
    for (int code = 100; code < MAX_CODE; code++){
        if (counts[code] > 0) {
            printf(" code %d : %d\n", code, counts[code]);
        }
    }

    if (n_sizes > 0) {
        qsort(sizes, n_sizes, sizeof(long), cmp_long);
        
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