#include <cstdio>

int main() {
#ifdef ENABLE_FANCY
  printf("fancy mode is ON\n");
#else
  printf("fancy mode is off\n");
#endif

#ifdef MAX_ITEMS
  printf("MAX_ITEMS = %d\n", MAX_ITEMS);
#else
  printf("MAX_ITEMS is undefined\n");
#endif

  printf("version string = %s\n", VERSION_STRING);
  return 0;
}
