# 063 - Declaring and Selecting Platforms

**Concepts:** `platform()`, `parents`, `--platforms`

## Run it

```bash
P=//063_platforms

bazel build $P:target_report
cat bazel-bin/063_platforms/target.txt

bazel build $P:target_report --platforms=$P:linux_arm64
cat bazel-bin/063_platforms/target.txt

bazel build $P:target_report --platforms=$P:macos_arm64
cat bazel-bin/063_platforms/target.txt
```

Note that only the **select** resolves differently here - actually compiling
C++ for another architecture additionally requires a toolchain that can target
it (sample 129).

## Platform inheritance

```python
platform(
    name = "linux_x86_64_ci",
    parents = [":linux_x86_64"],
    constraint_values = ["//pkg:role_ci"],
)
```

`parents` takes exactly one platform in practice. The child inherits every
constraint and may add or override.

## Where platforms live

Convention is a single `//platforms` package at the repo root holding every
platform definition, with public visibility. Rule sets also ship their own -
for example `@rules_go//go/toolchain:linux_amd64`.

## The flags

```bash
--platforms=//platforms:linux_arm64          # what we are building FOR
--host_platform=//platforms:linux_x86_64     # where Bazel runs
--extra_execution_platforms=//platforms:remote_linux   # where actions may run
```

## Why a platform is better than `--cpu`

The legacy `--cpu=k8` style flags described only one dimension and every rule
set interpreted them slightly differently. A platform is an extensible set of
typed constraints that toolchain resolution can reason about - which is what
makes automatic toolchain selection possible.

## Key takeaway

Define platforms once, centrally. Then `--platforms` is the single switch that
retargets the entire build.
