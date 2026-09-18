#include <cstdio>
#include <vector>

#include "stats.h"

int main() {
  std::vector<double> v{1, 2, 3, 4};
  int failures = 0;
  if (Mean(v) != 2.5) { printf("FAIL Mean\n"); failures++; }
  if (Max(v) != 4.0)  { printf("FAIL Max\n");  failures++; }
  if (Mean({}) != 0.0) { printf("FAIL Mean empty\n"); failures++; }
  if (failures == 0) printf("all stats tests passed\n");
  return failures == 0 ? 0 : 1;
}
