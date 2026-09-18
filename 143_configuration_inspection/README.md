# 143 - Inspecting Configurations

**Concepts:** `bazel config`, `cquery`, configuration hashes

## The commands

```bash
C=//143_configuration_inspection

# Which configuration(s) does this target exist in?
bazel cquery $C:probe

# Output includes a hash:  //pkg:probe (9f8c2a1)

# List every configuration in the last build:
bazel config

# Dump one configuration in full:
bazel config 9f8c2a1

# Compare two configurations - the fastest way to find what differs:
bazel config <hash1> <hash2>
```

## Reading a cquery line

```
//143_configuration_inspection:probe (9f8c2a1)
                                                      ^^^^^^^
                                                      configuration hash
```

Two lines for the same label mean the target exists in **two configurations** -
usually because something applied a transition, or because it is used both as a
tool (`exec`) and as a dependency (`target`).

That is the single most useful diagnostic for "why is this being built twice?"

## The output directory encodes the configuration

```
bazel-out/k8-fastbuild/bin/...                  the default
bazel-out/k8-opt/bin/...                        -c opt
bazel-out/k8-opt-exec/bin/...                   exec configuration
bazel-out/k8-fastbuild-ST-455a243331c5/bin/...  a Starlark transition applied
```

The `ST-<hash>` suffix means a Starlark build setting differs. Sample 142
produces three of these, one per channel.

## Practical cquery

```bash
# What files does this produce, in this configuration?
bazel cquery $C:probe --output=files

# Full details as JSON
bazel cquery $C:probe --output=jsonproto

# Evaluate an expression against the configured target
bazel cquery $C:probe --output=starlark \
  --starlark:expr='target.label'

# Which deps survive the select()s?
bazel cquery "deps($C:probe)" --noimplicit_deps
```

## `query` vs `cquery`, restated

`query` works on the loading-phase graph and does **not** resolve `select()`,
transitions, or toolchains. `cquery` works after analysis and sees the real,
configured graph.

If a query result disagrees with what actually got built, you probably wanted
`cquery`.

## Diagnosing configuration explosion

Symptoms: analysis is slow, memory is high, the same target builds many times.

```bash
bazel config | wc -l            # how many configurations exist?
bazel cquery //... --output=label | sort | uniq -c | sort -rn | head
```

The second command shows which labels appear in the most configurations. The
usual culprit is a transition applied too high in the graph.

## Key takeaway

`bazel config` and `cquery` are how you see the configured graph. Two cquery
lines for one label means two configurations - find out why.
