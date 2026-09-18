# 036 - Using bazel_skylib

**Concepts:** skylib rules, portability over genrule

## Run it

```bash
bazel build //036_using_skylib:all
cat bazel-bin/036_using_skylib/config.json
cat bazel-bin/036_using_skylib/config.backup.json
```

## What skylib is

`bazel_skylib` is the standard library of the Bazel ecosystem: small, correct,
well-tested rules and Starlark helpers that almost every repo needs.

## The rules you will use most

| Rule | Replaces |
|------|----------|
| `write_file` | `genrule(cmd = "echo ... > $@")` |
| `copy_file` | `genrule(cmd = "cp $< $@")` |
| `expand_template` | `genrule(cmd = "sed s/X/Y/ ...")` |
| `diff_test` | A hand-written golden-file comparison |
| `build_test` | "does this target even build?" in CI |
| `run_binary` | `genrule` that invokes a tool |

## The Starlark helpers

```python
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:shell.bzl", "shell")
load("@bazel_skylib//lib:selects.bzl", "selects")

paths.join("a", "b")        # "a/b"
paths.basename("a/b.txt")   # "b.txt"
shell.quote(user_string)    # safe interpolation into a command line
```

## Why prefer skylib over genrule

A `genrule` runs a shell command, so it needs a shell, and `cp`/`sed`/`echo`
differ across platforms. `write_file` and `copy_file` are implemented as native
Bazel actions - no shell, no portability surprises, better error messages.

## Key takeaway

Before writing a genrule, check whether skylib already has the rule. It usually
does, and its version is the portable one.
