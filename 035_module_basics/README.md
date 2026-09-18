# 035 - MODULE.bazel and bazel_dep

**Concepts:** bzlmod, `bazel_dep`, the Bazel Central Registry

## Run it

```bash
bazel build //035_module_basics:hello_from_skylib
cat bazel-bin/035_module_basics/hello.txt
```

## WORKSPACE is gone

Bazel 9 removed `WORKSPACE` entirely. External dependencies are declared in
`MODULE.bazel` using **bzlmod**:

```python
module(name = "bazel_samples", version = "1.0.0")

bazel_dep(name = "bazel_skylib", version = "1.8.2")
bazel_dep(name = "rules_cc", version = "0.2.17")
```

That is the whole declaration. No URL, no SHA256, no transitive dependency
list - Bazel resolves all of it from the **Bazel Central Registry**
(bcr.bazel.build).

## Why this replaced WORKSPACE

WORKSPACE had no notion of versions. If two of your dependencies each needed a
different version of a third library, whichever `http_archive` ran first won,
silently. bzlmod does real **version resolution**: it walks the whole
dependency graph and selects one compatible version of each module
(Minimal Version Selection).

## Inspect the graph

```bash
bazel mod graph               # the full resolved dependency tree
bazel mod deps bazel_skylib   # what one module pulls in
bazel mod explain rules_cc    # why this version was chosen
```

## Repository names

A module `foo` becomes the repository `@foo`, so you load from it as
`@bazel_skylib//rules:write_file.bzl`. Sample 067 covers renaming.

## Key takeaway

`bazel_dep(name, version)` is the whole external-dependency story for anything
published to the registry. Samples 066-070 cover the cases that are not.
