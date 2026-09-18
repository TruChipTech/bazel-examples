# 212 - One Image Definition, Many Architectures

**Concepts:** split transitions, `ctx.split_attr`, `target_platform_has_constraint`

## Run it

```bash
bazel build //212_multiarch_transition:all_arches
cat bazel-bin/212_multiarch_transition/all_arches_manifest.txt
```

```
linux_amd64 sha256:...
linux_arm64 sha256:...
linux_armv7 sha256:...
```

Three different image digests. **One** `oci_image` declaration.

## The split transition

```python
def _impl(settings, attr):
    return {
        platform: {"//command_line_option:platforms": str(label)}
        for platform, label in attr.platforms.items()
    }
```

Returning a **dict of dicts** tells Bazel to build the dependency once per key.
The attribute then arrives as a dict:

```python
for key, target in ctx.split_attr.image.items():
    ...
```

**Gotcha:** the value type follows the *attribute* type, not the transition:

| Attribute | `ctx.split_attr[key]` is |
|-----------|--------------------------|
| `attr.label` | a single `Target` |
| `attr.label_list` | a `list` of `Target` |

Iterating the first case gives `type 'Target' is not iterable` - a confusing
message, because nothing in the transition suggests the shape changed. Sample
142 uses `attr.label_list` and therefore gets lists.

This is the mechanism behind universal binaries, multi-ABI Android APKs and
multi-arch container manifests (sample 142).

## Why not just list three targets?

Sample 205 did exactly that, and it works. It also means:

- Three places to update when the entrypoint changes
- Nothing stops arm64 drifting from amd64
- Adding a platform is a copy-paste

With a transition the definition exists once and the platform list is data.

## Branching without `select()`

```python
ctx.target_platform_has_constraint(
    ctx.attr._aarch64[platform_common.ConstraintValueInfo])
```

This asks "is the current target platform aarch64?" **inside a rule
implementation**, with no `config_setting` and no `select()`. For a rule that
must compute something per architecture it is far cleaner than a combinatorial
set of config settings (compare sample 140).

## The cost

Three platforms means the subgraph is analyzed and built three times - three
sets of actions, three cache entries, three output directories. That is
inherent to cross-building, but it is why you apply the transition as close to
the leaves as possible (sample 193).

## Key takeaway

A split transition turns "build this for every platform" into data. Read the
results back through `ctx.split_attr`.
