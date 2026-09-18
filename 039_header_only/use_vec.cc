#include <cstdio>

#include "vec.h"

int main() {
  Vec2 a{1, 2}, b{3, 4};
  Vec2 c = a + b;
  printf("a+b = (%.1f, %.1f)\n", c.x, c.y);
  printf("a.b = %.1f\n", a.Dot(b));
  return 0;
}
