# 116 - depset: Transitive Data Without Quadratic Cost

**Concepts:** `depset`, `to_list()`, deduplication

## Run it

```bash
bazel build //116_depset_basics:top
cat bazel-bin/116_depset_basics/top.txt
```

`top` sees 4 files. `a.txt` arrives through both `left` and `right` but appears
once - depsets deduplicate.

## The problem depsets solve

Naively accumulating transitive data with lists:

```python
all_files = ctx.files.srcs
for dep in ctx.attr.deps:
    all_files = all_files + dep[Info].files      # copies the whole list
```

In a dependency chain of depth N, the deepest node's files get copied N times.
Build graphs are deep - this is O(n²) time *and* memory, and it is the classic
way to make a Bazel build unusably slow.

## The depset solution

```python
files = depset(
    direct = ctx.files.srcs,
    transitive = [dep[Info].files for dep in ctx.attr.deps],
)
```

O(1). The depset is a node in a DAG that mirrors the build graph; nothing is
copied. Children are shared between parents rather than duplicated.

## `to_list()` is the expensive part

```python
files.to_list()      # O(n): traverses and flattens
```

Rules:

- Call it **once**, as late as possible.
- **Never** call it in a loop or in a function called per dependency.
- Prefer passing the depset straight to `ctx.actions.run(inputs = ...)` or
  `args.add_all(...)`, both of which consume depsets directly without
  flattening in Starlark.

```python
args.add_all(files)                   # good - no flattening
args.add_all(files.to_list())         # wasteful
```

## Depsets are immutable

```python
d = depset([a])
d2 = depset([b], transitive = [d])    # new depset; d is unchanged
```

## When a plain list is fine

For a rule's **direct** attributes - `ctx.files.srcs`, a handful of flags - a
list is correct and simpler. Depsets are for data that accumulates *through the
dependency graph*.

## Key takeaway

`depset(direct = ..., transitive = [...])` is the single most important
performance idiom in Starlark. Reach for `to_list()` reluctantly.
