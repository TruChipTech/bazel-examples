# 025 - Compilation Modes

**Concepts:** `-c fastbuild|dbg|opt`, `NDEBUG`, output dirs

## Run it

```bash
bazel run -c fastbuild //025_compilation_modes:modes
bazel run -c dbg       //025_compilation_modes:modes
bazel run -c opt       //025_compilation_modes:modes
```

## The three modes

| Mode | Optimization | Debug info | `NDEBUG` | Use for |
|------|--------------|-----------|----------|---------|
| `fastbuild` (default) | none | minimal | no | Everyday iteration |
| `dbg` | none | full `-g` | no | Stepping in a debugger |
| `opt` | `-O2` | stripped | **yes** | Releases, benchmarks |

## Each mode gets its own output tree

```bash
ls bazel-out/
# k8-fastbuild/  k8-dbg/  k8-opt/
```

This is why switching modes does not throw away the other mode's cache -
`bazel build -c opt` then `bazel build -c dbg` then back to `opt` is fast both
times. The configuration is part of the output path.

## `assert()` silently disappears in opt

`-c opt` defines `NDEBUG`, which makes `assert()` compile to nothing. Code that
does real work inside an `assert()` will behave differently in release builds.
This is standard C/C++ behavior, but Bazel makes it easy to hit by accident
because the mode is a flag rather than a separate build directory.

## Key takeaway

`-c` selects a configuration, and configurations are cached independently.
Always benchmark with `-c opt`; always debug with `-c dbg`.
