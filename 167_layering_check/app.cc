#include <cstdio>

#include "mid.h"
// mid depends on lib_public, so lib_public.h is reachable TRANSITIVELY.
// Uncommenting the next line compiles fine by default, but is exactly what
// layering_check rejects: app does not declare a dependency on lib_public.
// #include "lib_public.h"

int main() {
  printf("mid = %d\n", mid_value());
  return 0;
}
