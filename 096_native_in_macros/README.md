# 096 - The `native` Module

**Concepts:** `native.*`, package context, macro helpers

## Run it

```bash
bazel test //096_native_in_macros:mathx
bazel build //096_native_in_macros:where_am_i
cat bazel-bin/096_native_in_macros/location.txt
```

## The rule

| Where | How you call a native rule |
|-------|---------------------------|
| BUILD file | `filegroup(...)` |
| `.bzl` file | `native.filegroup(...)` |

The `native` prefix is required in `.bzl` files because they have no implicit
BUILD namespace. Using it in a BUILD file is an error (and buildifier warns).

## Which rules are native?

`filegroup`, `genrule`, `test_suite`, `alias`, `config_setting`,
`package_group`, `exports_files`, `existing_rule`, `glob`, `package`.

Everything language-specific (`cc_library`, `py_binary`, `java_test`) now lives
in a rule set and must be `load()`ed, in `.bzl` and BUILD files alike.

## The context functions

```python
native.package_name()      # "096_native_in_macros"
native.repository_name()   # "@" for the main repo
native.package_relative_label(":x")
```

Valid only during loading. Calling them in a rule *implementation* (analysis
phase) is an error - use `ctx.label.package` there instead.

## `native.existing_rule` - use with care

```python
native.existing_rules()             # every target declared SO FAR in this package
native.existing_rule("some_target")
```

This lets a macro inspect what came before it, which makes the result depend on
**declaration order** in the BUILD file. It is legal, occasionally necessary for
migration tooling, and a reliable source of confusing bugs. Symbolic macros
(sample 052) forbid it entirely.

## The pattern in this sample

```python
def library_with_tests(name, srcs, test_files):
    py_library(name = name + "_lib", srcs = srcs)
    for src in test_files:
        py_test(name = src.replace(".py", ""), srcs = [src], ...)
    native.test_suite(name = name, tests = [...])
```

One call, N test targets, one suite. This is the most common real-world macro
shape.

## Key takeaway

`native.` for built-in rules inside `.bzl` files; `load()` for everything else.
Avoid `existing_rule` unless you have no alternative.
