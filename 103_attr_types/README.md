# 103 - Attribute Types and Validation

**Concepts:** `values`, `mandatory`, `providers`, `fail()`

## Run it

```bash
bazel build //103_attr_types:all
cat bazel-bin/103_attr_types/prod.conf
```

Then uncomment one of the failing examples in the BUILD file.

## The complete attr catalogue

```python
attr.string()          attr.string_list()      attr.string_dict()
attr.int()             attr.int_list()         attr.string_list_dict()
attr.bool()
attr.label()           attr.label_list()       attr.label_keyed_string_dict()
attr.output()          attr.output_list()
```

## Declarative validation

| Parameter | Effect |
|-----------|--------|
| `mandatory = True` | Caller must supply it |
| `default = x` | Used when omitted |
| `values = [...]` | Allowlist for strings/ints |
| `allow_files = True` | Label may point at source files |
| `allow_files = [".c"]` | ...with these extensions only |
| `allow_single_file = True` | Exactly one file |
| `providers = [CcInfo]` | Dependencies must provide these |
| `cfg = "exec"` | Build the dep for the execution platform |
| `executable = True` | The dep must be runnable |
| `doc = "..."` | Documentation |

Prefer these over hand-written checks: they produce better messages and are
visible to tooling and documentation generators.

## `providers` is the important one

```python
# In Bazel 9, CcInfo is not a global - load it first:
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

"deps": attr.label_list(providers = [CcInfo]),
```

(Bazel 9 removed the built-in provider globals. `CcInfo`, `JavaInfo`,
`PyInfo` and friends now live in their rule sets. The error message names the
exact `load()` line to add.)

Now passing a `filegroup` fails immediately:

```
ERROR: '//x:y' does not have mandatory provider 'CcInfo'
```

rather than failing deep inside your implementation with an attribute error.
It is the closest thing a rule has to a type signature.

## Imperative validation with `fail()`

Cross-attribute rules cannot be expressed declaratively:

```python
if ctx.attr.tier == "premium" and ctx.attr.replicas < 2:
    fail("%s: premium tier requires at least 2 replicas" % ctx.label)
```

Always include `ctx.label` in the message. A failure that does not say *which
target* is at fault is nearly useless in a large build.

## Key takeaway

Validate as early and as declaratively as you can. Every constraint you encode
is an error message someone does not have to debug.
