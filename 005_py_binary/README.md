# 005 - Python Binaries

**Concepts:** `py_binary`, `main`, launcher scripts

## Run it

```bash
bazel run //005_py_binary:wordcount -- apple banana apple cherry apple
```

## What Bazel actually produces

`py_binary` does not compile anything. It produces a launcher in `bazel-bin/`
plus a **runfiles** directory holding every file the program declared. The
launcher sets `PYTHONPATH` to that directory before handing control to Python.

Look at what was produced:

```bash
bazel build //005_py_binary:wordcount
ls bazel-bin/005_py_binary/
```

## Why this matters

Because imports resolve through declared runfiles rather than the ambient
filesystem, a `py_binary` that builds on your laptop runs the same way in CI.
An import of a module you forgot to declare fails immediately instead of
silently picking up a file that happens to be in the current directory.

## Key takeaway

`bazel run` builds *and* executes. `bazel build` only produces the launcher -
useful when you want to inspect the output without running it.
