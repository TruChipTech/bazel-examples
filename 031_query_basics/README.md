# 031 - bazel query Basics

**Concepts:** `query`, `deps`, `rdeps`, `somepath`

`bazel query` answers questions about the build graph **without building
anything**. It works on the graph as written in BUILD files (the loading-phase
graph).

## The essential queries

```bash
Q=//031_query_basics

# Every target in a package
bazel query $Q:all

# Everything this target depends on, transitively
bazel query "deps($Q:top)"

# Direct dependencies only (depth 1)
bazel query "deps($Q:top, 1)"

# Reverse: who depends on :base?
bazel query "rdeps($Q:all, $Q:base)"

# Why does top depend on base? Show one path.
bazel query "somepath($Q:top, $Q:base)"

# Show ALL paths
bazel query "allpaths($Q:top, $Q:base)"

# Only targets of a given rule kind
bazel query "kind(py_library, $Q:all)"

# Which files feed this target?
bazel query "labels(srcs, $Q:top)"
```

## Useful output formats

```bash
bazel query "deps($Q:top)" --output=label_kind   # prefix each with its rule type
bazel query "deps($Q:top)" --output=build        # reconstructed BUILD syntax
bazel query "deps($Q:top)" --output=graph        # Graphviz
```

Render the graph:

```bash
bazel query "deps($Q:top)" --output=graph --noimplicit_deps > graph.dot
```

## `--noimplicit_deps` is your friend

Without it, `deps()` includes every toolchain and compiler target Bazel added
behind the scenes - often hundreds of nodes that drown out your own code.

## Key takeaway

`query` is how you answer "what depends on this?" before you change it. It
costs nothing because it never leaves the loading phase.
