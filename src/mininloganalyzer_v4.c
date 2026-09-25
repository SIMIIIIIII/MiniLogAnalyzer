#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

#define MAX_LINE 2048
#define MAX_CODE 600

static int cmp_long(const void *a, const void *b)
{
    long la = *(const long *)a, lb = *(const long *)b;
    return (la > lb) - (la < lb);
}

static long percentile(long *sorted, long n, double p)
{
    if (n == 0)
        return 0;
    long idx = (long)(p / 100.0 * (n - 1));
    return sorted[idx];
}

static int parse_two_ints(const char *s, int *a, long *b)
{
    while (*s == ' ')
        s++;
    if (*s < '0' || *s > '9')
        return 0;

    long v1 = 0;
    while (*s >= '0' && *s <= '9')
    {
        v1 = v1 * 10 + (*s - '0');
        s++;
    }

    while (*s == ' ')
        s++;
    if (*s < '0' || *s > '9')
        return 0;

    long v2 = 0;
    while (*s >= '0' && *s <= '9')
    {
        v2 = v2 * 10 + (*s - '0');
        s++;
    }
    *a = (int)v1;
    *b = v2;
    return 1;
}

int main(int argc, char *argv[])
{
    if (argc != 2)
    {
        fprintf(stderr, "usage: %s <fichier.log>\n", argv[0]);
        return 1;
    }

    int fd = open(argv[1], O_RDONLY);

    struct stat st;
    fstat(fd, &st);
    long file_size = st.st_size;

    char *data = mmap(NULL, file_size, PROT_READ, MAP_PRIVATE, fd, 0);
    if (data == MAP_FAILED)
    {
        perror("mmap");
        return 1;
    }

    char *line_start = data;
    long total_lines = 0;
    int counts[MAX_CODE] = {0};
    long capacity = 1024, n_sizes = 0;
    long *sizes = malloc(capacity * sizeof(long));

    if (sizes == NULL)
    {
        fprintf(stderr, "malloc a echoue\n");
        return 1;
    }

    for (long i = 0; i < file_size; i++)
    {
        if (data[i] == '\n')
        {
            long size_line = &data[i] - line_start;
            char line[size_line + 1];
            memcpy(line, line_start, size_line);
            line[size_line] = '\0';

            char *quote = strrchr(line, '"');

            if (quote == NULL)
                continue;
            int code = 0;
            long size = 0;

            if (parse_two_ints(quote + 1, &code, &size))
            {
                if (code >= 0 && code < MAX_CODE)
                    counts[code]++;
                if (n_sizes == capacity)
                {
                    capacity *= 2;
                    // tableau dynamique : on double
                    long *tmp = realloc(sizes, capacity * sizeof(long));
                    if (tmp == NULL)
                    {
                        fprintf(stderr, "realloc a echoue\n");
                        return 1;
                    }
                    sizes = tmp;
                }
                sizes[n_sizes++] = size;
            }

            line_start = &data[i + 1];
            total_lines++;
        }
    }
    munmap(data, file_size);
    close(fd);

    printf("Lignes traitees : %ld\n", total_lines);

    for (int code = 100; code < MAX_CODE; code++)
    {
        if (counts[code] > 0)
            printf(" code %d : %d\n", code, counts[code]);
    }

    if (n_sizes > 0)
    {
        qsort(sizes, n_sizes, sizeof(long), cmp_long);

        // tri necessaire pour median/percentiles
        double sum = 0;
        for (long i = 0; i < n_sizes; i++)
            sum += sizes[i];

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