# 133 - Aggregating Output Groups in an Aspect

**Concepts:** transitive output groups, aspect-driven codegen

## Run it

```bash
bazel build //133_aspect_output_groups:handlers \
  --aspects=//133_aspect_output_groups:docgen.bzl%docgen_aspect \
  --output_groups=docs

cat bazel-bin/133_aspect_output_groups/*.doc
```

You get documentation for `handlers`, `services` **and** `models` - the whole
closure, from one top-level request.

## The aggregation that makes this work

```python
transitive = [dep[DocsInfo].docs for dep in ctx.rule.attr.deps if DocsInfo in dep]
all_docs = depset(direct = own_docs, transitive = transitive)

return [
    DocsInfo(docs = all_docs),          # for the next level up
    OutputGroupInfo(docs = all_docs),   # for --output_groups
]
```

Sample 130 returned only the target's **own** file in its output group, so
`--output_groups` surfaced just the top-level one. Here the aspect carries the
accumulated depset in a provider and republishes it as the output group at
every level. Requesting the group on the top target therefore yields
everything.

This is the standard shape, and it is worth committing to memory:

1. Compute this target's own outputs.
2. Collect dependencies' outputs from the provider.
3. `depset(direct = own, transitive = collected)`.
4. Return it in **both** a provider and `OutputGroupInfo`.

## Aspects can create actions

Note that this aspect does not just read - it registers `ctx.actions.run_shell`
actions on targets it did not define. The generated docs are real build
artifacts, cached and parallelized like anything else.

That capability is what makes aspects powerful: `java_proto_library` works by
running an aspect over a `proto_library` graph and generating Java for every
node in it.

## Making it a target

Use the sample 132 pattern so CI gets the docs without a flag:

```python
doc_bundle(name = "docs", targets = ["//services:handlers"])
```

## Key takeaway

Return the aggregated depset in both a provider and `OutputGroupInfo` at every
level. That is what makes a single top-level request collect the whole graph.
