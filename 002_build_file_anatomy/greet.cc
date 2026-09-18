#include <cstdio>

int main(int argc, char** argv) {
  const char* who = (argc > 1) ? argv[1] : "world";
  printf("greetings, %s\n", who);
  return 0;
}
