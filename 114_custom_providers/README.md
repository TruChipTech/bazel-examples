# 114 - Custom Providers

**Concepts:** `provider()`, typed data between rules

## Run it

```bash
bazel build //114_custom_providers:web_bundle
cat bazel-bin/114_custom_providers/web_bundle.bundle
```

## What a provider is

A provider is the **typed interface between rules**. A rule cannot reach into
another rule's implementation, read its attributes, or inspect its actions.
The only thing it can see is the providers that rule returned.

```python
AssetInfo = provider(
    doc = "Information about a bundle of web assets.",
    fields = {
        "files": "depset of File",
        "kind": "string",
        "entry_point": "File or None",
    },
)
```

## Returning and consuming

```python
# Producer
return [DefaultInfo(...), AssetInfo(files = ..., kind = ..., entry_point = ...)]

# Consumer
info = ctx.attr.library[AssetInfo]
info.kind
```

Indexing with a provider type fails loudly if the target does not have it - so
combine it with `attr.label(providers = [AssetInfo])` to move that failure to
a clear analysis-time error instead.

## Always return `DefaultInfo` too

A rule that returns only a custom provider still works for rules that
understand it, but `bazel build` produces nothing and `srcs = [":target"]`
gets nothing. Returning both makes the target useful to generic consumers *and*
to specialized ones.

## Checking before indexing

```python
if AssetInfo in dep:
    info = dep[AssetInfo]
```

`in` tests for presence without failing - useful in aspects (sample 130) which
visit targets of every kind.

## The built-in providers follow the same pattern

| Provider | Carries |
|----------|---------|
| `DefaultInfo` | files, runfiles, executable |
| `CcInfo` | headers, linking info |
| `JavaInfo` | jars, compile-time classpath |
| `PyInfo` | transitive sources, imports |
| `OutputGroupInfo` | named extra output sets |
| `InstrumentedFilesInfo` | coverage metadata |

In Bazel 9 the language ones must be loaded from their rule sets.

## Key takeaway

Providers are the API boundary between rules. Declare `fields` with
documentation, and require them with `attr.label(providers = [...])`.
