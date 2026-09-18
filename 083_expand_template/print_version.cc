#include <cstdio>

#include "version.h"

int main() {
  printf("%s %s (%s)\n", APP_NAME, APP_VERSION, BUILD_CHANNEL);
  return 0;
}
