# 118 - The Transitive Collection Pattern

**Concepts:** a complete miniature rule set

## Run it

```bash
bazel build //118_transitive_pattern/app
cat bazel-bin/118_transitive_pattern/app/app.summary
```

`app` sees 3 sources, and `core` appears once despite arriving through two
paths.

## The shape every rule set has

```python
MyInfo = provider(fields = {"transitive_x": "depset", ...})

def _collect(ctx):
    return depset(
        direct = ctx.files.srcs,
        transitive = [dep[MyInfo].transitive_x for dep in ctx.attr.deps],
    )

def _library_impl(ctx):
    stuff = _collect(ctx)
    ...
    return [DefaultInfo(...), MyInfo(transitive_x = stuff, ...)]

def _binary_impl(ctx):
    stuff = _collect(ctx)       # same helper
    all_items = stuff.to_list() # flatten ONCE, at the leaf of the graph
```

Libraries **accumulate**; binaries **consume**. That is why `to_list()` appears
in `_binary_impl` and never in `_library_impl` - flattening at every library
would reintroduce the O(n²) cost depsets exist to avoid.

## Feeding depsets to actions directly

```python
args.add_all("--include", collected.includes, uniquify = True)
ctx.actions.run(inputs = collected.sources, ...)
```

Both `Args.add_all` and the `inputs` parameter accept depsets. Neither
flattens in Starlark - the expansion happens in Bazel's Java layer, lazily,
only if the action runs.

`uniquify = True` removes duplicate values in the expanded command line, which
matters for include paths.

## Why `_collect` is shared

`minilang_library` and `minilang_binary` need the same closure logic. Factoring
it out is not just tidiness - it guarantees the two rule kinds agree about what
"the transitive closure" means. Divergence there produces bugs where a library
compiles and the binary that links it does not.

## Compare with the real thing

This is the same structure as `CcInfo` (headers + linking context),
`JavaInfo` (compile jars + runtime jars) and `PyInfo` (transitive sources +
imports). Reading `rules_cc` after this sample is much easier.

## Key takeaway

Collect with `depset(direct=, transitive=)` in every library, flatten once in
the binary, and pass depsets to actions rather than lists.
