# 002 - BUILD File Anatomy

**Concepts:** phases, `package()`, attributes, Starlark

## Run it

```bash
bazel run //002_build_file_anatomy:greet -- Bazel
```

Everything after `--` is passed to your program, not to Bazel.

## The three phases

| Phase | What happens | What you debug it with |
|-------|--------------|------------------------|
| Loading | BUILD files parse, macros expand | `bazel query` |
| Analysis | Rules run, actions are created | `bazel cquery`, `bazel aquery` |
| Execution | Actions actually run | `bazel build`, `--verbose_failures` |

This separation is why Bazel can tell you *what would be built* without
building it, and why a syntax error in a BUILD file fails instantly.

## A BUILD file is not a script

It looks like Python, but there are no `if __name__`, no loops over the
filesystem, no `import`. You declare targets; Bazel decides execution order and
parallelism. Writing `print()` in a BUILD file emits a message during loading,
not during the build.

## Key takeaway

`package()` sets file-wide defaults and must be the first call. Individual
targets can override those defaults, as `visibility` does here.
