# 126 - Debugging Toolchain Resolution

**Concepts:** `--toolchain_resolution_debug`, common failures

## The main tool

```bash
D=//126_toolchain_debugging

bazel build $D:subject --toolchain_resolution_debug='.*'

# Narrow it to one toolchain type - the output is otherwise enormous:
bazel build $D:subject --toolchain_resolution_debug='.*compiler_type.*'
```

The flag takes a **regex** matched against toolchain type labels. It prints,
for each type: the candidates considered, the constraints checked, and why each
was accepted or rejected.

Note that changing this flag discards the analysis cache, so the next build is
slower. That is expected.

## Seeing what a target actually resolved to

```bash
bazel cquery $D:subject --output=starlark \
  --starlark:expr='providers(target)'
```

Or inspect the platforms in play:

```bash
bazel config                     # list configurations
bazel cquery $D:subject --output=jsonproto | head -40
```

## The failures you will actually hit

### "No matching toolchains found"

```
ERROR: While resolving toolchains for target //x:y: No matching toolchains
found for types //pkg:my_toolchain_type
```

Causes, in order of likelihood:

1. The toolchain was never registered (`register_toolchains` missing, or
   `--extra_toolchains` not passed).
2. Its `target_compatible_with` does not match the target platform.
3. Its `exec_compatible_with` does not match any execution platform.
4. The toolchain type label is misspelled in the rule's `toolchains = [...]`.

### A visibility error on an unrelated target

Registered toolchains are analyzed in **every** build. If one references a
non-visible target, an unrelated build fails. Make toolchain types and
implementations public (sample 125).

### The wrong toolchain wins

Resolution takes the **first** compatible candidate:

1. `--extra_toolchains` (last specified wins)
2. Root module `register_toolchains`, in order
3. Dependency modules

If the wrong one is chosen, the answer is almost always registration order or
a missing constraint on the one you expected to lose.

### It works locally, fails on CI

Usually a different execution platform - CI runs in a container whose
constraints do not match `exec_compatible_with`. Compare:

```bash
bazel info                     # locally
bazel build //x:y --toolchain_resolution_debug='.*type.*'   # on CI
```

## Making failures friendlier for your users

```python
my_rule = rule(
    ...,
    toolchains = [config_common.toolchain_type("//pkg:my_type", mandatory = False)],
)
```

With `mandatory = False`, `ctx.toolchains[...]` returns `None` instead of
failing, so your rule can emit its own message:

```python
tc = ctx.toolchains["//pkg:my_type"]
if tc == None:
    fail("%s: no compiler toolchain registered. Add register_toolchains(...) to MODULE.bazel." % ctx.label)
```

## Key takeaway

`--toolchain_resolution_debug` with a narrow regex answers almost every
toolchain question. Most failures are registration order, constraints, or
visibility.
