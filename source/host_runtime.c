#include <stdio.h>

int getint(void) {
    int x;
    scanf("%d", &x);
    return x;
}

void putint(int x) {
    printf("%d\n", x);
}
