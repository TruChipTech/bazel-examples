# 132 - Applying an Aspect From a Rule

**Concepts:** `attr.label_list(aspects = [...])`, productionizing aspects

## Run it

```bash
bazel build //132_aspect_from_rule:inventory
cat bazel-bin/132_aspect_from_rule/inventory.report
```

No `--aspects` flag. No `--output_groups`. Just a target.

## The two ways to apply an aspect

**From the command line** - ad hoc, for tooling and exploration:

```bash
bazel build //x:y --aspects=//pkg:defs.bzl%my_aspect --output_groups=my_group
```

**From a rule** - permanent, reviewable, part of the graph:

```python
"targets": attr.label_list(aspects = [size_aspect]),
```

## Why the rule form is usually what you want

| | Command line | From a rule |
|---|--------------|-------------|
| Discoverable | No - someone must know the incantation | Yes - it is a target |
| CI integration | A bespoke command | `bazel build //...` |
| Reviewable | Lives in a CI script | Lives in a BUILD file |
| Composable | No | Yes - other rules can depend on the output |
| Cacheable result | Outputs only | Full target caching |

IDE plugins use the command-line form because they are external tools. Anything
your team owns should generally be a rule.

## Aspect parameters from a rule

```python
size_aspect = aspect(
    implementation = _impl,
    attrs = {"detail": attr.string(default = "short", values = ["short", "full"])},
)
```

A **public** aspect attribute must be `attr.string` with an explicit `values`
list. That restriction exists because Bazel needs a finite set of aspect
configurations to key its analysis cache on.

For anything richer, put the parameter on the *rule* and have the rule act on
the aspect's providers afterwards.

## Reading the aspect's providers

```python
def _report_impl(ctx):
    all_entries = depset(transitive = [
        dep[SizeInfo].entries for dep in ctx.attr.targets
    ]).to_list()
```

Targets in an attribute with `aspects = [...]` carry the aspect's providers in
addition to their own.

## Key takeaway

`attr.label_list(aspects = [...])` turns an aspect into an ordinary build
target. Prefer it for anything the team depends on.
