# 189 - Profiling Starlark

**Concepts:** `--starlark_cpu_profile`, slow macros and rules

## The flag

```bash
bazel build //... --starlark_cpu_profile=/tmp/starlark.pprof
```

Produces a pprof profile of **Starlark evaluation only** - loading, macro
expansion, and rule implementation functions.

```bash
go tool pprof -top /tmp/starlark.pprof
go tool pprof -http=:8080 /tmp/starlark.pprof
```

## When you need it

The build profile (sample 157) tells you the **phase** that is slow. If it is
loading or analysis, this flag tells you **which Starlark code** is responsible.

Symptoms that point here:

- `bazel build --nobuild //...` (analysis only) is slow
- Loading takes many seconds on a repo that is not that large
- Adding a macro made everything slower

## The usual culprits

| Pattern | Cost | Fix |
|---------|------|-----|
| `depset.to_list()` in a loop | O(n²) | Flatten once (sample 190) |
| List concatenation for transitive data | O(n²) | Use `depset` |
| Huge `glob()` patterns | Filesystem traversal | Narrow them (sample 192) |
| Deeply nested macros | Loading time | Flatten the layers |
| String building in a loop | Allocation churn | `"".join(list)` |
| `native.existing_rules()` | Scans the package | Avoid it |

## `to_list()` in a loop is the classic

```python
# O(n^2): flattens the depset once per dependency
for dep in ctx.attr.deps:
    for f in dep[Info].files.to_list():
        ...

# O(n): flatten once
all_files = depset(transitive = [d[Info].files for d in ctx.attr.deps]).to_list()
```

This single mistake is responsible for most "our analysis phase takes four
minutes" reports.

## Measuring loading in isolation

```bash
# Loading + analysis only, no execution
time bazel build --nobuild //...

# Loading only
time bazel query //... > /dev/null
```

Comparing the two separates loading cost from analysis cost.

## Complementary flags

```bash
--experimental_command_profile=cpu    # profiles the Bazel JVM itself
--profile=/tmp/prof.gz                # whole-build timeline (sample 157)
--announce_rc                         # confirm which flags are active
```

If `--starlark_cpu_profile` shows nothing interesting but analysis is still
slow, the cost is in Bazel's own machinery - usually too many configured
targets (sample 193) rather than slow Starlark.

## Key takeaway

Profile the phase first, then the Starlark. `to_list()` in a loop and list
concatenation for transitive data cause most Starlark slowness.
