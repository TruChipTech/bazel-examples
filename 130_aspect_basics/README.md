# 130 - Aspects: The Basics

**Concepts:** `aspect()`, `attr_aspects`, `ctx.rule`

## Run it

```bash
A=//130_aspect_basics

bazel build $A:root \
  --aspects=//130_aspect_basics:count.bzl%file_count_aspect \
  --output_groups=file_count

cat bazel-bin/130_aspect_basics/root.filecount
```

```
//130_aspect_basics:root: 1 own, 4 transitive
```

The aspect **ran on all three** targets - that is how the transitive count
reaches 4 (root 1 + middle 2 + leaf 1). But `--output_groups` collects the
group only from the **top-level target you requested**, so only
`root.filecount` is reported.

To surface every visited target's file, the aspect must aggregate its
dependencies' output groups into its own - see sample 133.

## What an aspect is

An aspect attaches **extra analysis** to targets in an existing graph, without
modifying the rules that created them.

```
       Your rules:          py_library -> py_library -> py_library
       The aspect:              |            |             |
                             visits       visits        visits
```

You did not write `py_library`. You cannot change it. But an aspect can visit
every one of them and produce something new.

## The implementation signature

```python
def _impl(target, ctx):
    ...
```

| Parameter | What it is |
|-----------|-----------|
| `target` | The `Target` being visited (its providers, label, files) |
| `ctx.rule.attr` | The **visited rule's** attributes |
| `ctx.rule.kind` | The visited rule's type, e.g. `"py_library"` |
| `ctx.attr` | The **aspect's own** parameters |

Confusing `ctx.attr` with `ctx.rule.attr` is the most common aspect bug.

## `attr_aspects` controls propagation

```python
attr_aspects = ["deps"]              # follow deps edges
attr_aspects = ["deps", "exports"]   # follow both
attr_aspects = ["*"]                 # follow every label attribute
```

The aspect runs on the requested target, then propagates along those
attributes, recursively.

## Defensive coding is mandatory

An aspect visits rules of **every kind**, including ones you have never heard
of. Always guard:

```python
if hasattr(ctx.rule.attr, "srcs"):
    ...
if FileCountInfo in dep:
    ...
```

Omitting these produces crashes on unrelated targets - the classic way an
aspect breaks somebody else's build.

## What aspects are used for

| Use | Example |
|-----|---------|
| IDE integration | Extract compile flags for every target |
| Linting | Run a checker over all sources in a graph |
| Code generation | Generate bindings for every proto in a closure |
| Dependency analysis | License scanning, SBOM generation |
| Metrics | Count lines, actions, or targets |

`rules_proto`'s language bindings and every IDE plugin for Bazel are built on
aspects.

## Key takeaway

An aspect adds analysis to a graph you do not own. `(target, ctx)`,
`ctx.rule.attr` for the visited rule, and defensive `hasattr` checks.
