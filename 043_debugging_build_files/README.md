# 043 - Debugging BUILD Files

**Concepts:** `print()`, `fail()`, `--output=build`, loading phase

## See the print output

```bash
bazel build //043_debugging_build_files:a
```

```
DEBUG: .../helpers.bzl:9:10: describe_target: name=a, 1 srcs
```

The message appears during **loading**, before anything is compiled. Run the
build twice: on the second run the package is cached and the message may not
reappear. Force it with `bazel build --nokeep_state_after_build` or by
touching the BUILD file.

## The debugging toolkit

| Tool | Answers |
|------|---------|
| `print(x)` | "What is this value during loading?" |
| `fail(msg)` | "Stop now and tell the caller why" |
| `bazel query --output=build //pkg:target` | "What did my macro actually generate?" |
| `bazel query 'deps(//pkg:t)'` | "What does this really depend on?" |
| `type(x)`, `dir(x)` | "What kind of object is this?" |

## `--output=build` is the one people forget

When a macro expands into six targets, this shows you the result as if someone
had written it by hand:

```bash
bazel query --output=build //043_debugging_build_files:a
```

This is the single best way to debug a macro (samples 051-052).

## Do not ship `print()`

Leftover `print()` calls spam every build in the repo. Bazel intentionally has
no log-level control for them - they are meant to be temporary.

## Key takeaway

BUILD files are code and debug like code. `print()` for values, `fail()` for
validation, `query --output=build` for "what did this expand to".
