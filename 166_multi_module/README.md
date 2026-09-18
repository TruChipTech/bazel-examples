# 166 - Multi-Module Repositories

**Concepts:** nested modules, `local_path_override`, splitting a repo

Sample 068 has a working nested module at
`068_local_path_override/greeting_lib`. This sample is about when
and why you would structure a repo that way.

## One module or several?

**One module** (the default, and right for most repos):

```
/MODULE.bazel
  services/
  libs/
```

Everything shares one dependency graph, one version of every external module,
one `bazel build //...`.

**Several modules**:

```
/MODULE.bazel              the root
  libs/core/MODULE.bazel   a separately publishable module
  libs/net/MODULE.bazel
```

Choose this only when a directory must be **independently consumable** - by
another repository, by an external team, or by open-source users.

## The cost of splitting

| Cost | Detail |
|------|--------|
| `//...` no longer covers everything | Each module builds separately |
| Cross-module refactors get harder | You cannot atomically change both sides |
| Version resolution between them | Even locally, they negotiate versions |
| `.bazelignore` maintenance | The outer repo must skip nested module dirs |

That last one is concrete: this repository's `.bazelignore` contains

```
068_local_path_override/greeting_lib
```

without which the outer module would try to load the nested module's packages
as its own.

## The development workflow

```python
# Root MODULE.bazel
bazel_dep(name = "core", version = "1.0.0")

local_path_override(module_name = "core", path = "libs/core")
```

Developers get live edits; consumers get the published version. Remember that
overrides apply **only in the root module** - a dependency's overrides are
ignored, which prevents a library from hijacking its consumers.

## A better middle ground

Before splitting, consider whether you actually want:

- **Visibility + `package_group`** (samples 015, 046) to enforce the boundary
- A **`bzl_library`** and clean public API to make the seam explicit
- **CODEOWNERS** for review ownership

These give you the architectural boundary without the build-system cost. Split
into modules when the code must genuinely ship separately - not to express
"these are different teams".

## Publishing

A module intended for others needs a `MODULE.bazel` with a real `version`, a
stable public API, and ideally a Bazel Central Registry entry (sample 196).

## Key takeaway

Default to one module. Split when a directory must be independently
consumable, and use `local_path_override` for day-to-day development across
the split.
