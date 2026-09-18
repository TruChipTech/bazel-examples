#include <cstdio>

#include "widget.h"

int main() {
  if (widget_id() != 99) {
    printf("FAIL\n");
    return 1;
  }
  printf("ok\n");
  return 0;
}
