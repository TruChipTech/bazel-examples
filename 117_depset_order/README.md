# 117 - depset Traversal Order

**Concepts:** `postorder`, `preorder`, `topological`, link order

## Run it

```bash
bazel build //117_depset_order:all
cat bazel-bin/117_depset_order/app_postorder.txt
cat bazel-bin/117_depset_order/app_pre_preorder.txt
```

`postorder` gives `libc -> libm -> app` (dependencies first).
`preorder` gives `app -> libm -> libc` (dependents first).

## The four orders

| Order | Traversal | Typical use |
|-------|-----------|-------------|
| `default` | Unspecified | **Everything**, unless order matters |
| `postorder` | Children before parents | Link order for some linkers |
| `preorder` | Parents before children | Include-path precedence |
| `topological` | Parents before children, deterministic | Ordered codegen |

## Why this exists at all

Linkers are order-sensitive. A traditional Unix linker resolves symbols in
command-line order, so a library must appear *after* the objects that reference
it. A rule set producing link command lines must therefore control the order in
which the transitive closure is flattened - that is what these orders are for.

## Orders must be compatible when merged

```python
depset(transitive = [postorder_depset, preorder_depset])
# ERROR: Order mismatch
```

A `default` depset can absorb any order, but two explicit, different orders
cannot be merged. In practice this means a rule set picks one order and uses it
consistently throughout.

## Use `default` unless you have a reason

`default` is the fastest and imposes no constraints on merging. If your data is
a *set* - inputs to an action, files to package, headers to expose - order is
irrelevant and `default` is correct.

Reach for an explicit order only when the consumer genuinely depends on
sequence.

## A caution

Order applies to `to_list()`. It says nothing about the order actions execute
in - that is determined by the dependency graph and Bazel's scheduler.

## Key takeaway

Pick `default` by default. Use `postorder`/`preorder` only when producing an
order-sensitive command line, and keep the choice consistent across the rule
set.
