# 174 - cquery in Depth

**Concepts:** configured queries, `select()` resolution

## The demonstration

```bash
C=//174_cquery_depth

# query sees BOTH select() branches - including the one that will never build
bazel query "deps($C:server)" --noimplicit_deps | grep backend

# cquery sees only the branch actually selected
bazel cquery "deps($C:server)" --noimplicit_deps | grep backend
```

On Linux, `query` reports both `epoll_backend` and `generic_backend`; `cquery`
reports only `epoll_backend`.

This is not a detail. Any script that computes "what does this target depend
on" with `query` will over-report on every target that uses `select()` - which,
in a cross-platform repo, is most of them.

## When you need cquery

| Question | Command |
|----------|---------|
| What will actually be built? | `cquery` |
| Which `select()` branch won? | `cquery` |
| What configuration is this in? | `cquery` |
| Where is the output file? | `cquery --output=files` |
| What does the BUILD file say? | `query` (faster, no analysis) |

## Useful invocations

```bash
# Output files for the current configuration
bazel cquery $C:server --output=files

# Full detail
bazel cquery $C:server --output=jsonproto | jq '.results[0].target.rule.name'

# Only targets of a kind, configured
bazel cquery "kind(cc_library, deps($C:server))"

# Under a different platform - the select resolves differently
bazel cquery "deps($C:server)" --platforms=//129_cross_compilation:linux_aarch64
```

## Configuration in the output

```
//174_cquery_depth:server (9f8c2a1)
```

The trailing hash is the configuration (sample 143). Two lines for one label
means the target is built twice - the fastest way to spot an unintended
transition.

## The cost

`cquery` runs loading **and analysis**, so it is much slower than `query` and
uses far more memory. On a large repo, `bazel cquery //...` can take minutes.

Narrow the scope:

```bash
bazel cquery "deps(//services/api:server)"     # not //...
```

## `--universe_scope`

```bash
bazel cquery "somepath(//a:a, //b:b)" --universe_scope=//a:a
```

`cquery` needs a universe to analyze against. For `rdeps` and path queries,
setting it explicitly is both faster and more predictable.

## Key takeaway

Use `cquery` whenever `select()`, transitions, or output paths are involved.
Use `query` when you want speed and only care about what the BUILD files say.
