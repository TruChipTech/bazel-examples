package com.example;

public class Greeter {
  private final String salutation;

  public Greeter(String salutation) {
    this.salutation = salutation;
  }

  public String greet(String who) {
    return salutation + ", " + who + "!";
  }
}
