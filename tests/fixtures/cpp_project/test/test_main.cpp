#include <cassert>

int add(int a, int b);

int main() {
    assert(add(5, 3) == 8);
    assert(add(0, 0) == 0);
    assert(add(-2, -3) == -5);
    return 0;
}

int add(int a, int b) {
    return a + b;
}
