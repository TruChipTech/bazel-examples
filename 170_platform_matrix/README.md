# 170 - Multi-Platform Build Matrices

**Concepts:** `--platforms` in CI, per-platform artifacts

## Try it

```bash
M=//170_platform_matrix
X=//129_cross_compilation

for p in linux_x86_64 linux_aarch64 linux_armv7; do
  echo "=== $p ==="
  bazel build $M:arch --platforms=$X:$p
  bazel cquery $M:arch --platforms=$X:$p --output=files | xargs cat
done
```

One target, three platforms, three different outputs - and each is cached
independently because the configuration is part of the output path.

## The CI shape

```yaml
strategy:
  matrix:
    platform: [linux_x86_64, linux_aarch64, darwin_arm64]
steps:
  - run: bazel build //... --platforms=//platforms:${{ matrix.platform }}
```

## Two ways to run a matrix

**Separate invocations** (above): simple, parallelizes across CI runners, each
gets its own log. The usual choice.

**One invocation with a split transition** (sample 142): a single rule builds
every platform and combines the results - required when you need one artifact
containing several architectures (a universal binary, a fat APK, a multi-arch
container manifest).

## Sharing cache across the matrix

Every platform is a different configuration, so they do not share action
results - but they **do** share:

- The repository cache (downloads happen once)
- Exec-configuration tools, if the execution platform is the same
- Analysis work for platform-independent targets

Point every matrix job at the same remote cache. The exec-configuration tools
alone are often a substantial fraction of a cold build.

## Skipping what cannot build

```python
cc_binary(
    name = "linux_only_tool",
    target_compatible_with = ["@platforms//os:linux"],
)
```

`bazel build //...` then skips it on other platforms instead of failing
(sample 128). This is what makes a single matrix command work unchanged across
every platform.

## Collecting the artifacts

```bash
for p in linux_x86_64 linux_aarch64; do
  bazel build //cmd:server --platforms=//platforms:$p
  cp "$(bazel cquery //cmd:server --platforms=//platforms:$p --output=files)" \
     "dist/server-$p"
done
```

`cquery --output=files` is the reliable way to locate an output whose path
depends on the configuration - `bazel-bin` points at only one of them.

## Key takeaway

`--platforms` is the one switch that retargets a build. Run it as a CI matrix,
share a remote cache across the jobs, and use `target_compatible_with` so one
command works everywhere.
