#include <cstdio>

#include "cache.h"
#include "storage.h"

int main() {
  Save("greeting", "hi there");
  printf("direct: %s\n", Load("greeting").c_str());
  printf("cached: %s\n", CachedLoad("greeting").c_str());
  return 0;
}
