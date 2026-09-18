# 097 - Generating a Test Matrix

**Concepts:** macro-generated targets, parameterized tests, tag filtering

## Run it

```bash
M=//097_test_matrix

bazel query $M:all                  # 4 tests + 1 suite, from one macro call
bazel test  $M:storage_matrix       # all of them
bazel test  $M:all --test_tag_filters=backend_disk    # just the disk ones
bazel test  $M:storage_matrix_disk_async --test_output=all
```

## Why generate rather than parameterize inside the test

A single test that loops over combinations gives you:

- One pass/fail result for the whole matrix
- No parallelism between combinations
- A full re-run when any one combination changes
- "the test failed" instead of "disk+async failed"

Separate targets give you the opposite of each. Bazel runs them in parallel,
caches them independently, and names the failure precisely.

## The macro

```python
for backend in backends:
    for mode in modes:
        py_test(
            name = "%s_%s_%s" % (name, backend, mode),
            args = ["--backend=" + backend, "--mode=" + mode],
            tags = ["backend_" + backend, "mode_" + mode],
            ...
        )
```

The generated tags are what make slicing possible later:

```bash
bazel test //... --test_tag_filters=mode_async
```

## Excluding combinations

Real matrices have holes - combinations that are not supported or not worth
testing:

```python
for backend in backends:
    for mode in modes:
        if backend == "remote" and mode == "sync":
            continue    # legal: this is inside a .bzl function
        py_test(...)
```

Remember that an `if` statement is legal in a `.bzl` function but **not** at
the top level of a BUILD file (sample 054).

## Naming discipline

Predictable names (`<name>_<backend>_<mode>`) mean a human can guess the label
of a failing combination without reading the macro. Random or index-based names
(`test_1`, `test_2`) make CI output useless.

## Key takeaway

Generate one target per combination. You get parallelism, caching, and precise
failure attribution for the cost of a nested loop.
