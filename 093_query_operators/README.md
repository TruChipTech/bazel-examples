# 093 - Query Operators in Depth

**Concepts:** query operators, `cquery` vs `query`, impact analysis

Set `Q=//093_query_operators` first.

## The operators worth memorizing

```bash
# What does this need?
bazel query "deps($Q:server)"
bazel query "deps($Q:server, 1)"           # direct only

# Who needs this? (the "what will I break?" query)
bazel query "rdeps(//..., $Q:util)"
bazel query "rdeps(//..., $Q:util, 1)"     # direct reverse deps only

# How are these connected?
bazel query "somepath($Q:server, $Q:util)" # one path
bazel query "allpaths($Q:server, $Q:util)" # every path

# Filter by rule type
bazel query "kind(py_library, deps($Q:server))"
bazel query "kind('.*_test', //...)"        # regex

# Filter by label pattern
bazel query "filter('.*cache.*', deps($Q:server))"

# Set operations
bazel query "deps($Q:api) intersect deps($Q:cache)"
bazel query "deps($Q:server) except deps($Q:api)"
bazel query "deps($Q:api) union deps($Q:storage)"

# Attribute search - find every target with a given tag
bazel query "attr(tags, 'manual', //...)"
bazel query "attr(testonly, 1, //...)"

# Which package owns this file?
bazel query "$Q/util.py"
```

## The two queries you will use daily

**Before changing something:**
```bash
bazel query "rdeps(//..., //lib:thing)" --output=label
```
Everything that could break.

**Before deleting something:**
```bash
bazel query "rdeps(//..., //lib:thing)" --output=label | wc -l
```
If it is 0, the target is dead code.

## query vs cquery vs aquery

| Command | Operates on | Sees `select()` resolved? |
|---------|-------------|---------------------------|
| `query` | The loading-phase graph | **No** - reports all branches |
| `cquery` | The analysis-phase graph | **Yes** - one configuration |
| `aquery` | The action graph | Yes, plus the commands |

This matters: `bazel query "deps(//x:y)"` on a target with a `select()` shows
dependencies from *every* branch, including ones that will never be built.
`cquery` shows what is actually in this build.

```bash
bazel cquery "deps($Q:server)"
bazel cquery "deps($Q:server)" --output=files
```

Samples 174-176 cover `cquery` and `aquery` in depth.

## Performance note

`rdeps(//..., X)` loads every package in the repo. In a large monorepo that is
slow. Narrow the universe when you can:

```bash
bazel query "rdeps(//services/..., //lib:thing)"
```

## Key takeaway

`deps` answers "what do I need", `rdeps` answers "what needs me", `somepath`
answers "why". Use `cquery` when `select()` is involved.
