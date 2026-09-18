#include <cstdio>

int main(int argc, char** argv) {
  printf("service starting\n");
  for (int i = 1; i < argc; ++i) printf("  arg: %s\n", argv[i]);
  return 0;
}
