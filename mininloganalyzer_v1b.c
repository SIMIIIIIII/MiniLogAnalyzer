#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>

#define MAX_LINE 2048
#define MAX_CODE 600

typedef struct node {
    long value;
    struct node *next;
} node_t;

void free_node(node_t **node) {
    while (node != NULL && *node != NULL) {
        node_t *next = (*node)->next;
        free(*node);
        *node = next;
    }
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
    long n_sizes = 0;
    node_t *head = NULL;

    while (fgets(line, MAX_LINE, f) != NULL) {
        total_lines++;
        char *quote = strrchr(line, '"');

        if (quote == NULL) continue;
        int code = 0; long size = 0;

        if (sscanf(quote + 1, " %d %ld", &code, &size) == 2) {
            if (code >= 0 && code < MAX_CODE) counts[code]++;
            
            node_t *node = malloc(sizeof(node_t));

            if (node == NULL) {
                fprintf(stderr, "malloc a echoue\n");
                return 1;
            }

            node->value = size;
            node->next = head;
            head = node;
            n_sizes++;
        }
    }

    fclose(f);

    printf("Lignes traitees : %ld\n", total_lines);

    for (int code = 100; code < MAX_CODE; code++){
        if (counts[code] > 0) printf(" code %d : %d\n", code, counts[code]);
    }

    if (n_sizes > 0) {

        // tri necessaire pour median/percentiles
        double sum = 0;
        long min = LONG_MAX;
        long max = 0;
        for (node_t *cur = head; cur != NULL; cur = cur->next) {
            sum += cur->value;
            if (cur->value >= 0 && cur->value < min) min = cur->value;
            if (cur->value > max) max = cur->value;
        }
        printf("\nTailles de reponse (n=%ld octets) :\n", n_sizes);
        printf(" min: %ld\n", min);
        printf(" max: %ld\n", max);
        printf(" moyenne : %.1f\n", sum / n_sizes);
    }
    free_node(&head);
    return 0;
}