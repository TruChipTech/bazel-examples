# 050 - Capstone: A Complete Small Project

**Concepts:** everything from 001-049 together

## Run it

```bash
C=//050_capstone_basics

bazel build $C/...
bazel run   $C/cli:analyze -- 050_capstone_basics/testdata/values.txt
bazel test  $C:all_tests
```

## The layout

```
050_capstone_basics/
  BUILD.bazel          test_suite - one label for CI
  lib/                 cc_library + its unit test
  cli/                 cc_binary + an end-to-end sh_test
  testdata/            fixtures, shared via filegroup
```

This mirrors how a real Bazel project is organized: **one package per cohesive
unit**, tests living next to the code they test, fixtures exposed through a
filegroup.

## What each piece demonstrates

| Concept | Where |
|---------|-------|
| Library + binary split | `lib/` and `cli/` |
| Unit test | `lib:stats_test` |
| End-to-end test | `cli:smoke_test` - runs the real binary |
| `data` for runtime files | `cli:smoke_test` depends on the binary *and* the fixtures |
| `filegroup` | `testdata:values` |
| Subpackage visibility | `__subpackages__` keeps the library internal to this sample |
| `test_suite` | One stable label for CI |
| Tags | `unit` vs `integration` |

## Try the filtering

```bash
bazel test $C/... --test_tag_filters=unit         # fast feedback
bazel test $C/... --test_tag_filters=integration  # the slow ones
```

## Where this leads

That is enough to read and write ordinary BUILD files. Samples 051-100 cover
making them *composable*: macros, `select()`, external dependencies and build
settings.
