package com.example.calc;

/**
 * A test with a plain main() method. Bazel's test contract is just "exit 0 on
 * success", so no test framework is strictly required - which is handy when
 * you do not want to pull JUnit from Maven.
 */
public class CalculatorTest {
  private static int failures = 0;

  private static void check(String what, int got, int want) {
    if (got != want) {
      System.out.printf("FAIL %s: got %d, want %d%n", what, got, want);
      failures++;
    } else {
      System.out.printf("ok   %s%n", what);
    }
  }

  public static void main(String[] args) {
    check("add(2,3)", Calculator.add(2, 3), 5);
    check("factorial(0)", Calculator.factorial(0), 1);
    check("factorial(5)", Calculator.factorial(5), 120);

    try {
      Calculator.factorial(-1);
      System.out.println("FAIL factorial(-1): expected an exception");
      failures++;
    } catch (IllegalArgumentException expected) {
      System.out.println("ok   factorial(-1) throws");
    }

    if (failures > 0) {
      System.exit(1);
    }
    System.out.println("all java tests passed");
  }
}
