#include <cstdio>

#include "storage.h"

int main() {
  Save("k", "v");
  if (Load("k") != "v") {
    printf("FAIL: round trip broken\n");
    return 1;
  }
  printf("ok: storage round trip\n");
  return 0;
}
