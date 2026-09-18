# 051 - Legacy Macros

**Concepts:** macros, loading phase, `--output=build`

## Run it

```bash
M=//051_legacy_macros

bazel query $M:all          # three targets from one macro call
bazel test  $M:greeter_test
bazel run   $M:greeter_bin -- Bazel

# See exactly what the macro expanded into:
bazel query --output=build $M:greeter_test
```

## A macro is not a rule

| | Macro | Rule |
|---|-------|------|
| Runs during | Loading | Analysis |
| Creates | Other targets | Actions |
| Bazel sees | Only the expansion | The rule itself |
| Written as | A Starlark function | `rule(implementation = ...)` |

A macro is a **code generator for BUILD files**. By the time analysis starts,
`py_module` no longer exists - there are just three ordinary targets.

## Why this matters when debugging

Error messages point at the *generated* targets, not at your macro call. If
`:greeter_test` fails, nothing mentions `py_module`. That is why
`--output=build` is essential: it shows the expansion as if hand-written.

## Conventions

- Name derived targets `name + "_suffix"` so they are predictable.
- Accept `**kwargs` and forward it, so callers can pass `visibility`, `tags`,
  etc. without you enumerating every attribute.
- Validate arguments with `fail()` and a clear message - the caller has no
  other way to find out what went wrong.

## The limitation that motivated symbolic macros

A legacy macro can do anything: read globals, create targets with arbitrary
names, silently mutate lists passed to it. Bazel cannot reason about it at all,
so tooling cannot tell which target came from where. Sample 052 shows the fix.

## Key takeaway

Macros remove repetition in BUILD files. They add no build-time cost, because
they are gone before the build starts.
