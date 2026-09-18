#include <cstdio>

#include "public_api.h"
// Uncommenting the next line breaks the build: private_impl.h is in srcs,
// not hdrs, so it is NOT part of this library's public interface.
// #include "private_impl.h"

int main() {
  printf("PublicCompute(5) = %d\n", PublicCompute(5));
  return 0;
}
