# 028 - test_suite: Grouping Tests

**Concepts:** `test_suite`, tag-based suites, composition

## Run it

```bash
bazel test //028_test_suite:smoke
bazel test //028_test_suite:fast_tests
bazel test //028_test_suite:everything
```

## Two ways to define membership

**Explicit list** - stable and reviewable:

```python
test_suite(name = "smoke", tests = [":a_test", ":b_test"])
```

**By tag** - self-maintaining, but membership is invisible in the BUILD file:

```python
test_suite(name = "fast_tests", tags = ["fast"])
```

A tag-based suite covers tests in *its own package only*. Note that `tags` on a
`test_suite` filters the tests it would otherwise include; it does not search
the repo.

## Why not just use `//pkg/...`?

Wildcards are positional - they follow the directory layout. A `test_suite` is
semantic: `//:presubmit` can pull tests from twenty packages that have nothing
in common except that they must pass before merge. CI then references one
stable label forever.

## test_suite produces nothing

Like `filegroup`, it is pure grouping. `bazel build` on a suite builds the
tests but runs nothing.

## Key takeaway

Give CI a stable label (`//:presubmit`, `//:nightly`) and change the membership
in the BUILD file rather than in the CI config.
