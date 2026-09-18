# 040 - A Binary With Runtime Data

**Concepts:** `data` + `filegroup`, packaging for runtime

## Run it

```bash
bazel run //040_binary_with_data:service
```

## Inspect the runfiles

```bash
bazel build //040_binary_with_data:service
find bazel-bin/040_binary_with_data/service.runfiles -name '*.json' -o -name '*.txt'
```

Both config files were staged next to the executable, preserving their
directory structure relative to the workspace root.

## The pattern

```python
filegroup(name = "config_files", srcs = glob(["config/*"]))

py_binary(name = "service", data = [":config_files"], ...)
py_test(name = "service_test", data = [":config_files"], ...)
```

The binary and its test share one declaration. Add a config file and both pick
it up.

## Why this matters for deployment

Because the runfiles tree is complete and self-describing, packaging the
service is a matter of archiving that tree - there is no separate "don't forget
to copy the config directory" step. Sample 086 turns exactly this into a tarball
with `pkg_tar`.

## Key takeaway

`data` + `filegroup` + `glob` is the standard way to attach a directory of
runtime assets to a program.
