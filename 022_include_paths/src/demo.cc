#include <cstdio>

#include "mylib/strings.h"

int main() {
  printf("%s\n", Repeat("ab", 3).c_str());
  return 0;
}
