# 1 "source/example_clang.c"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 361 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "source/example_clang.c" 2
int getint(void);
void putint(int x);

int calc(int n) {
    int i = 1;
    int sum = 0;

    while (i <= n) {
        if (i % 2 == 0) {
            sum = sum + i * 2;
        } else {
            sum = sum + i;
        }

        i = i + 1;
    }

    return sum;
}

int main(void) {
    int n;
    n = getint();

    int result;
    result = calc(n);

    putint(result);

    return 0;
}
