# 068 - local_path_override: Using a Module From Disk

**Concepts:** `local_path_override`, local development workflow

## Run it

```bash
bazel run //068_local_path_override:main -- Alice
```

Then edit `greeting_lib/greeting/polite.py` and run again - the change is
picked up immediately, with no publish step.

## The declaration

```python
# Root MODULE.bazel
bazel_dep(name = "greeting_lib", version = "1.0.0")

local_path_override(
    module_name = "greeting_lib",
    path = "068_local_path_override/greeting_lib",
)
```

The `bazel_dep` stays exactly as it would be for a registry module. The
override only changes **where the module comes from**.

## Why this is the most useful override

You are fixing a bug in a shared library that your service depends on. Without
an override you would have to publish a version, wait, and bump the dependency
for every test cycle. With one line you point at your local checkout:

```python
local_path_override(module_name = "shared_lib", path = "../shared_lib")
```

Delete the line when you are done. Nothing else in the build changes.

## Overrides only apply in the root module

If module A depends on B, and B has a `local_path_override`, that override is
**ignored** when A is built as someone's dependency. Only the root module's
overrides take effect. This prevents a library from hijacking its consumers'
dependency graph.

## The `.bazelignore` detail

Because this nested module lives inside the outer repository, the outer repo
would otherwise try to load its packages too. This repo's `.bazelignore` lists
the directory so `//...` does not descend into it:

```
068_local_path_override/greeting_lib
```

A module checked out beside the repo rather than inside it needs no such entry.

## Key takeaway

`local_path_override` is the standard workflow for developing two modules at
once. It is a root-module-only escape hatch, which is exactly right.
