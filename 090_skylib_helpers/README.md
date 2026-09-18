# 090 - The skylib Helper Libraries

**Concepts:** `paths`, `shell`, `dicts`, `collections`, `versions`

## Run it

```bash
bazel build //090_skylib_helpers:helper_demo
cat bazel-bin/090_skylib_helpers/helpers.txt
```

## The libraries

### `paths` - path string manipulation

```python
load("@bazel_skylib//lib:paths.bzl", "paths")

paths.join("a", "b", "c")            # "a/b/c"
paths.basename("a/b/c.txt")          # "c.txt"
paths.dirname("a/b/c.txt")           # "a/b"
paths.replace_extension("x.cc", ".o")# "x.o"
paths.normalize("a/./b/../c")        # "a/c"
paths.relativize("a/b/c", "a")       # "b/c"
paths.is_absolute("/x")              # True
```

Hand-rolled `split("/")[-1]` breaks on edge cases. Use these.

### `shell` - safe command-line quoting

```python
load("@bazel_skylib//lib:shell.bzl", "shell")

cmd = "process " + shell.quote(user_supplied_value)
```

**This is a security matter, not a style preference.** Interpolating an
unquoted value into a genrule `cmd` is command injection. Any time a value
that you did not write ends up in a shell string, quote it.

### `dicts` - non-mutating merges

```python
dicts.add(base, override)            # new dict; later keys win
```

Starlark values freeze after loading, so `base.update(...)` fails at runtime.
`dicts.add` returns a new dict.

### `collections` - list utilities

```python
collections.uniq([1, 2, 1, 3])       # [1, 2, 3], order preserved
collections.before_each("-I", ["a", "b"])   # ["-I", "a", "-I", "b"]
```

### `versions` - version comparison

```python
versions.is_at_least("6.0.0", native.bazel_version)
versions.check(minimum_bazel_version = "7.0.0")
```

Used by rule sets to fail early with a clear message on an unsupported Bazel.

### `types` - runtime type checks

```python
load("@bazel_skylib//lib:types.bzl", "types")
types.is_list(x)   # and is_string, is_dict, is_depset, ...
```

Useful for giving macro callers a good error instead of a stack trace.

## Key takeaway

skylib's helpers are small, correct and already a dependency of your build.
Reach for them instead of re-implementing string manipulation - especially
`shell.quote`.
