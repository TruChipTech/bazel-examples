# 088 - build_test: Making "It Compiles" a Test

**Concepts:** `build_test`, CI coverage of non-test targets

## Run it

```bash
bazel test //088_build_test:everything_builds
```

## The problem it solves

CI commonly runs:

```bash
bazel test //...
```

That builds every test and everything tests depend on - but **not** targets
nothing depends on. Your example programs, docs generators, debug tools and
rarely-used library variants are invisible to that command, and they rot.

The naive fix is `bazel build //... && bazel test //...`, which works but is
coarse: you cannot tag, filter, or shard it, and a broken example blocks the
whole build rather than reporting as one failing test.

`build_test` gives each group of such targets a test identity:

```python
build_test(
    name = "examples_build",
    targets = ["//examples:all"],
)
```

## It does not run anything

`build_test` only proves the targets **build**. It never executes them. For a
library with no tests that is still meaningful - it catches syntax errors, type
errors, broken dependencies and API drift.

## Good uses

| Target kind | Why |
|-------------|-----|
| Example code | Proves the examples still match the API |
| Generated documentation | Catches a broken generator |
| Platform variants | Cross-compiled targets nobody runs locally |
| Rarely used tools | Debug utilities, migration scripts |
| `//...:all` in a leaf package | Cheap smoke coverage |

## Key takeaway

If a target matters but nothing depends on it, wrap it in a `build_test` or CI
will silently stop checking it.
