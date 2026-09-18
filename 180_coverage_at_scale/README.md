# 180 - Coverage at Scale

**Concepts:** `--combined_report`, instrumentation filters, CI integration

## Run it

```bash
C=//180_coverage_at_scale

bazel coverage $C/... --combined_report=lcov \
  --instrumentation_filter="^//180_coverage_at_scale"

cat bazel-out/_coverage/_coverage_report.dat | head -30
```

## What you will actually see here, and why

On this repo the report is generated but the line counts are empty:

```
SF:180_coverage_at_scale/core.py
FNF:0
FNH:0
LH:0        <- lines hit
LF:0        <- lines found
end_of_record
```

Bazel produced the LCOV structure - it knows which files were instrumented -
but no line data was collected, because **`rules_python` needs a coverage tool
configured**. Without one there is no `coverage.py` to record execution.

```python
# MODULE.bazel
python = use_extension("@rules_python//python/extensions:python.bzl", "python")
python.toolchain(
    python_version = "3.12",
    configure_coverage_tool = True,      # <- this is the missing piece
)
```

This is worth seeing rather than hiding: `bazel coverage` exiting 0 with a
report file is **not** evidence that coverage is working. Always check that
`LF` (lines found) is non-zero before trusting a coverage number or wiring it
into a CI gate.

Once the tool is configured, `unused_helper` in `core.py` shows as uncovered.

## `--instrumentation_filter` is not optional at scale

By default Bazel instruments **everything** the tests depend on, including
every third-party library. The result is a report where your own code is a
rounding error, and coverage runs take far longer than they should.

```
# .bazelrc
coverage --instrumentation_filter=^//src/,^//lib/
```

The filter is a regex over target labels. Set it once, repo-wide.

## Combining reports

```bash
bazel coverage //... --combined_report=lcov
```

Merges every test's data into `bazel-out/_coverage/_coverage_report.dat`.
Without it you get per-test files and have to merge them yourself.

```bash
genhtml bazel-out/_coverage/_coverage_report.dat --output-directory /tmp/cov
open /tmp/cov/index.html
```

## Coverage is slow - budget for it

Instrumented builds are a separate configuration, so they do not share cache
entries with your normal build. A coverage run is effectively a second full
build plus slower test execution.

Practical policy:

| Pipeline | Coverage |
|----------|----------|
| Presubmit | No |
| Postsubmit on main | Yes |
| Nightly | Yes, with the HTML report published |

Running coverage on every presubmit is the most common way teams make their
CI unbearably slow for little benefit.

## Per-language support

| Language | Backend | Notes |
|----------|---------|-------|
| Python | `coverage.py` | Works well |
| Java | JaCoCo | Works well |
| C++ | gcov / llvm-cov | Needs a matching toolchain |
| Go | Native | Works well |

For C++, `--experimental_use_llvm_covmap` with a Clang toolchain gives better
results than gcov.

## What coverage does not tell you

Coverage measures **execution**, not verification. A test that calls a function
and asserts nothing produces the same number as a thorough one. Treat a sudden
*drop* as a signal worth investigating, and a specific uncovered branch as a
prompt for a test. Treat a repo-wide percentage target as a metric people will
game.

## Key takeaway

Set `--instrumentation_filter` repo-wide, combine reports, and run coverage
postsubmit rather than on every presubmit.
