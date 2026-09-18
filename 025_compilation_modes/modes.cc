#include <cstdio>

int main() {
#ifdef NDEBUG
  printf("NDEBUG is defined  -> optimized build (-c opt)\n");
#else
  printf("NDEBUG is NOT defined -> debug or fastbuild\n");
#endif
  printf("assert() is %s\n",
#ifdef NDEBUG
         "disabled"
#else
         "enabled"
#endif
  );
  return 0;
}
