# 012 - Runfiles: Files Available at Runtime

**Concepts:** runfiles, `data`, build time vs run time

## Run it

```bash
bazel run //012_data_and_runfiles:reader
```

## See the runfiles tree

```bash
bazel build //012_data_and_runfiles:reader
find bazel-bin/012_data_and_runfiles/reader.runfiles -maxdepth 3
```

You will see a directory tree that mirrors the workspace, containing the
launcher, the Python interpreter wiring, and `greeting.txt`.

## Build time vs run time

| Attribute | When it is used | Example |
|-----------|-----------------|---------|
| `srcs` | Build time | source files to compile |
| `deps` | Build time | libraries to link/import |
| `data` | Run time | configs, fixtures, golden files |

A compiler needs `srcs`. A program reading a config at startup needs `data`.
Putting a runtime file in `srcs` often still "works" for interpreted languages,
which is exactly why the mistake survives until someone builds a
self-contained artifact and the file goes missing.

## Runfiles are transitive

If `reader` depends on a library that has its own `data`, those files appear in
`reader`'s runfiles too. You never have to re-declare a dependency's data.

## Key takeaway

`data` answers "what does this program need to *read* when it runs?" - and
that question has to be answered explicitly, just like dependencies.
