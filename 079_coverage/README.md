# 079 - Code Coverage

**Concepts:** `bazel coverage`, LCOV, `--combined_report`

## Run it

```bash
bazel coverage //079_coverage:shapes_test

# Bazel prints the path to the LCOV report, typically:
cat bazel-out/_coverage/_coverage_report.dat
```

The `triangle` branch and the whole `perimeter` function will show as
uncovered.

## The command

`bazel coverage` is `bazel test` plus instrumentation. It:

1. Rebuilds the instrumented targets
2. Runs the tests
3. Collects per-test LCOV data
4. Optionally merges it into one report

```bash
bazel coverage //... --combined_report=lcov
```

## Controlling what gets instrumented

By default Bazel instruments everything the test depends on - including
third-party code, which buries your own numbers.

```bash
bazel coverage //... \
  --instrumentation_filter="^//079_coverage"
```

The filter is a regex over target labels. Most repos set a sensible default in
`.bazelrc`:

```
coverage --instrumentation_filter=^//src/,^//lib/
```

## Turning LCOV into HTML

```bash
genhtml bazel-out/_coverage/_coverage_report.dat --output-directory /tmp/cov
```

`genhtml` ships with `lcov`. CI systems usually consume the `.dat` directly.

## Language support

| Language | Support |
|----------|---------|
| Python | Good, via `coverage.py` |
| Java | Good, via JaCoCo |
| C++ | Good, via gcov/llvm-cov |
| Go | Good, via the native Go tooling |

## Use it as a signal, not a target

Coverage tells you what was *executed*, not what was *verified* - a test with
no assertions still produces 100% coverage. Treat a sudden drop as worth
investigating and a specific uncovered branch as worth a test; treat a
repo-wide percentage goal with suspicion.

## Key takeaway

`bazel coverage` works out of the box. Set `--instrumentation_filter` or the
numbers will be meaningless.
