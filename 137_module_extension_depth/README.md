# 137 - Module Extensions in Depth

**Concepts:** `module_ctx.modules`, aggregation, `extension_metadata`

## Run it

```bash
bazel build //137_module_extension_depth:show_registry
cat bazel-bin/137_module_extension_depth/registry_copy.txt

bazel mod show_extension //137_module_extension_depth:extension.bzl%registry
```

## The global view

```python
def _registry_impl(module_ctx):
    for module in module_ctx.modules:
        for component in module.tags.component:
            ...
```

The extension runs **once per build**, and `module_ctx.modules` contains every
module that used it. That is the design's whole purpose.

Consider five modules each needing a Python package. If each created its own
repository, you would get five copies at five versions. Because the extension
sees all five requests at once, it can resolve **one** consistent set - which
is exactly what `rules_python`'s pip extension and `rules_jvm_external`'s maven
extension do.

## `module.is_root`

```python
source = "root" if module.is_root else module.name
```

The root module is the one being built. Extensions commonly let the root
override or veto what dependencies requested - a policy only the root should
have.

## Conflict resolution is your job

```python
if component.name in seen:
    fail("component '%s' declared twice (by %s and %s)" % (...))
```

Bazel does not resolve conflicting tags for you. Decide the policy explicitly:
fail, let the root win, take the highest version, or merge. Whatever you pick,
make the failure message name both sources.

## `extension_metadata`

```python
return module_ctx.extension_metadata(
    root_module_direct_deps = ["component_registry"],
    root_module_direct_dev_deps = [],
    reproducible = True,
)
```

| Field | Effect |
|-------|--------|
| `root_module_direct_deps` | Lets `bazel mod tidy` write the right `use_repo` |
| `reproducible = True` | The result depends only on the tags, so it need not be recorded in the lockfile |

Declaring `reproducible = True` when the extension actually reads the
environment or the network is a correctness bug - the lockfile will not capture
the difference.

## `os_dependent` / `arch_dependent`

```python
registry = module_extension(implementation = _impl, os_dependent = True)
```

Tells Bazel the result varies by platform, so it is keyed accordingly in the
lockfile.

## Key takeaway

An extension's power is the global view of every module's requests. Use it to
resolve conflicts centrally, and describe the result honestly with
`extension_metadata`.
