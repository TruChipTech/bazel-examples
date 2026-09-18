# 073 - Java Tests

**Concepts:** `java_test`, `test_class`, `use_testrunner`

## Run it

```bash
bazel test //073_java_test:calculator_test --test_output=all
```

## Two ways to write a java_test

**With JUnit** (what most projects do):

```python
java_test(
    name = "calculator_test",
    srcs = ["CalculatorTest.java"],
    test_class = "com.example.calc.CalculatorTest",
    deps = [
        ":calculator",
        "@maven//:junit_junit",
        "@maven//:org_hamcrest_hamcrest_core",
    ],
)
```

`test_class` tells Bazel's JUnit runner which class to load. It must be the
**fully qualified** name.

**Without a framework** (this sample):

```python
java_test(
    name = "calculator_test",
    main_class = "com.example.calc.CalculatorTest",
    use_testrunner = False,
)
```

Bazel just runs `main()` and checks the exit code. Useful for bootstrapping, or
when the dependency cost of a framework is not worth it.

## Getting JUnit: rules_jvm_external

Maven dependencies come from the `rules_jvm_external` module:

```python
# MODULE.bazel
bazel_dep(name = "rules_jvm_external", version = "6.7")

maven = use_extension("@rules_jvm_external//:extensions.bzl", "maven")
maven.install(
    artifacts = [
        "junit:junit:4.13.2",
        "com.google.guava:guava:33.0.0-jre",
    ],
)
use_repo(maven, "maven")
```

Then `@maven//:junit_junit` is a normal dependency. It is a module extension
(sample 070) that resolves the whole Maven graph and pins it in a lockfile.

## The common `test_class` mistake

```
ERROR: Class not found: CalculatorTest
```

almost always means `test_class` is missing the package prefix, or the Java
package does not match the directory layout.

## Key takeaway

`java_test` defaults to JUnit; `use_testrunner = False` gives you the plain
exit-code contract. Maven dependencies arrive via `rules_jvm_external`.
