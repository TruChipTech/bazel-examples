#include <cstdio>
#include <cstring>

#include "zlib.h"

int main() {
  const char* input = "bazel bazel bazel bazel bazel bazel bazel bazel";
  uLong src_len = strlen(input) + 1;
  uLong dst_len = compressBound(src_len);
  Bytef buffer[512];

  if (compress(buffer, &dst_len, reinterpret_cast<const Bytef*>(input), src_len) != Z_OK) {
    printf("compression failed\n");
    return 1;
  }
  printf("zlib version : %s\n", zlibVersion());
  printf("original     : %lu bytes\n", src_len);
  printf("compressed   : %lu bytes\n", dst_len);
  return 0;
}
