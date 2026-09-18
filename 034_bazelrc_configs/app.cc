#include <cstdio>

int main() {
#ifdef NDEBUG
  printf("optimized (--config=release)\n");
#else
  printf("not optimized (--config=dev or default)\n");
#endif
  return 0;
}
