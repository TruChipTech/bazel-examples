#include <cstdio>

// Note: NO __DATE__ or __TIME__. Bazel redacts them for C++, but relying on
// that is worse than not using them.
int main() {
  printf("deterministic output\n");
  return 0;
}
