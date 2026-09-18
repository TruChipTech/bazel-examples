# 190 - depset Performance

**Concepts:** the O(n²) trap, measuring it, fixing it

## Run it

```bash
D=//190_depset_performance

bazel build $D:slow_24 --starlark_cpu_profile=/tmp/slow.pprof
bazel build $D:fast_24 --starlark_cpu_profile=/tmp/fast.pprof

cat bazel-bin/190_depset_performance/slow_24.slow
cat bazel-bin/190_depset_performance/fast_24.fast
```

Note that the **counts differ**: the list version reports 25 (one copy of the
file per level, all retained) while the depset version reports 1, because
depsets deduplicate.

That difference is not cosmetic - it is the memory blow-up, visible.

## The anti-pattern

```python
all_files = list(ctx.files.srcs)
for dep in ctx.attr.deps:
    all_files = all_files + dep[Info].files      # copies the whole list
```

At depth N, the deepest node's files are copied N times. Time and memory are
both O(n²). Real dependency graphs are deep and wide, so this goes from "fine"
to "the analysis phase takes ten minutes" with no warning.

## The fix

```python
all_files = depset(
    direct = ctx.files.srcs,
    transitive = [dep[Info].files for dep in ctx.attr.deps],
)
```

O(1). The depset is a node referencing its children; children are shared
between parents rather than duplicated.

## The three rules

**1. Transitive data is always a depset.**
```python
fields = {"transitive_srcs": "depset of File"}   # not "list of File"
```

**2. `to_list()` once, at the consumer.**
```python
# Libraries accumulate; only the binary flattens.
```

**3. Never `to_list()` inside a loop.**
```python
for dep in ctx.attr.deps:
    for f in dep[Info].files.to_list():   # O(n^2) again
```

## Pass depsets to actions directly

```python
ctx.actions.run(inputs = my_depset, ...)     # no flattening in Starlark
args.add_all(my_depset)                      # expanded lazily, in Java
```

Both accept depsets. Calling `.to_list()` to feed them undoes the benefit.

## Detecting it in an existing repo

```bash
bazel build //... --starlark_cpu_profile=/tmp/p.pprof
go tool pprof -top /tmp/p.pprof | head -20
```

`to_list` or depset construction near the top is the signature.

Or grep for the shape:

```bash
grep -rn 'to_list()' --include='*.bzl' . | grep -B2 'for '
```

## Key takeaway

Depsets are not an optimization to apply later - using a list for transitive
data is a correctness-of-scale bug that only appears once the graph is large.
