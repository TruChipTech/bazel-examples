# 071 - Inspecting the Module Graph

**Concepts:** `bazel mod`, lockfiles, dependency debugging

## The commands

```bash
# The whole resolved dependency tree
bazel mod graph

# Only the path(s) leading to one module - the most useful one
bazel mod graph --from=rules_cc

# Why is THIS version selected?
bazel mod explain protobuf

# Everything about one module: its deps, its extensions, its repo name
bazel mod show_repo rules_python

# What does an extension actually generate?
bazel mod show_extension @rules_python//python/extensions:python.bzl%python

# Add any missing use_repo() calls automatically
bazel mod tidy

# The repo mapping for the root module
bazel mod dump_repo_mapping ""
```

## `bazel mod graph` output

```
<root> (bazel_samples@1.0.0)
├───bazel_skylib@1.8.2
│   ├───platforms@1.0.0 (*)
│   └───rules_license@1.0.0
├───platforms@1.0.0
...
```

`(*)` means "already shown above" - the graph is a DAG, printed as a tree.

## The question it answers most often

> Why is version X of this module in my build?

```bash
bazel mod explain protobuf
```

It shows which module requested which version and which one MVS selected.
Without this, diagnosing a version conflict means reading every dependency's
`MODULE.bazel` by hand.

## The lockfile

Bazel writes `MODULE.bazel.lock` recording exactly what was resolved. Commit
it: it makes builds reproducible across machines and over time, and it lets
Bazel skip re-resolution.

```bash
bazel mod deps --lockfile_mode=update   # refresh it
bazel build //... --lockfile_mode=error # CI: fail if the lockfile is stale
```

`--lockfile_mode` values: `update` (default), `refresh`, `error`, `off`.
Sample 139 covers the lockfile in depth, and sample 164 the update workflow.

## Key takeaway

`bazel mod graph` and `bazel mod explain` replace guesswork about external
dependencies with a direct answer.
