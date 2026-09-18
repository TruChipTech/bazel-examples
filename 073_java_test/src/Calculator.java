package com.example.calc;

public class Calculator {
  public static int add(int a, int b) {
    return a + b;
  }

  public static int factorial(int n) {
    if (n < 0) throw new IllegalArgumentException("negative");
    int result = 1;
    for (int i = 2; i <= n; i++) result *= i;
    return result;
  }
}
