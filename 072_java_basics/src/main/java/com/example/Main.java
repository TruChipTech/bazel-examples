package com.example;

public class Main {
  public static void main(String[] args) {
    Greeter greeter = new Greeter("Hello");
    String who = args.length > 0 ? args[0] : "world";
    System.out.println(greeter.greet(who));
  }
}
