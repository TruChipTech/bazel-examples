# 070 - Module Extensions

**Concepts:** `module_extension`, `tag_class`, `use_repo`

## Run it

```bash
bazel build //070_module_extension:show_metadata
cat bazel-bin/070_module_extension/metadata_copy.txt
```

The `@build_metadata_repo` repository exists nowhere on disk - the extension
generated it.

## The three pieces

**1. The extension implementation** reads what modules declared and creates
repositories:

```python
def _impl(module_ctx):
    for module in module_ctx.modules:
        for record in module.tags.record:
            ...
    metadata_repo(name = "build_metadata_repo", ...)
```

**2. The tag schema** declares what callers may pass:

```python
_record = tag_class(attrs = {"name": attr.string(mandatory = True),
                             "channel": attr.string(default = "stable")})

build_metadata = module_extension(implementation = _impl,
                                  tag_classes = {"record": _record})
```

**3. The call site** in `MODULE.bazel`:

```python
build_metadata = use_extension("//070_module_extension:extension.bzl", "build_metadata")
build_metadata.record(name = "release", channel = "stable")
use_repo(build_metadata, "build_metadata_repo")
```

## `use_repo` is not optional

The extension can create ten repositories, but only the ones named in
`use_repo` become visible to your module. Forgetting it produces:

```
ERROR: No repository visible as '@build_metadata_repo'
```

Bazel will usually print the exact `use_repo(...)` line to add. You can also
run `bazel mod tidy` to have it fixed automatically.

## Why extensions exist

The real use case is **aggregating requests from many modules**. When five
modules each declare a Python pip requirement, the extension sees all five
tags at once and can resolve one consistent set of packages - rather than five
conflicting repositories. That is what `rules_python`'s `pip` extension and
`rules_jvm_external`'s `maven` extension do.

## `use_repo_rule` vs `module_extension`

| Need | Use |
|------|-----|
| One repository, no logic | `use_repo_rule` (sample 066) |
| Logic, or input from several modules | `module_extension` |

## Key takeaway

A module extension is the bridge between declarative `MODULE.bazel` data and
imperative repository creation. Samples 137-139 go deeper.
