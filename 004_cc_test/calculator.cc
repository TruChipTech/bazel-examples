#include "calculator.h"

int Add(int a, int b) { return a + b; }

int Divide(int numerator, int denominator) {
  if (denominator == 0) return 0;
  return numerator / denominator;
}
