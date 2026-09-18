#include <cstdio>
#include <cstdlib>

#include "calculator.h"

static int failures = 0;

static void Expect(const char* what, int got, int want) {
  if (got != want) {
    printf("FAIL %s: got %d, want %d\n", what, got, want);
    failures++;
  } else {
    printf("ok   %s\n", what);
  }
}

int main() {
  Expect("Add(2,3)", Add(2, 3), 5);
  Expect("Add(-1,1)", Add(-1, 1), 0);
  Expect("Divide(10,2)", Divide(10, 2), 5);
  Expect("Divide(1,0)", Divide(1, 0), 0);
  // A test binary signals failure with a non-zero exit code.
  return failures == 0 ? 0 : 1;
}
