# 129 - Cross-Compilation

**Concepts:** `--platforms`, target-constrained toolchains

## Run it

```bash
X=//129_cross_compilation
TC="--extra_toolchains=$X:x86_64_toolchain,$X:aarch64_toolchain,$X:armv7_toolchain"

bazel build $X:arch $TC --platforms=$X:linux_x86_64
cat bazel-bin/129_cross_compilation/arch.h

bazel build $X:arch $TC --platforms=$X:linux_aarch64
cat bazel-bin/129_cross_compilation/arch.h

bazel build $X:arch $TC --platforms=$X:linux_armv7
cat bazel-bin/129_cross_compilation/arch.h
```

One target, three different outputs, no BUILD file changes.

## The mechanism

```python
toolchain(
    name = "aarch64_toolchain",
    toolchain_type = ":codegen_type",
    toolchain = ":aarch64_impl",
    target_compatible_with = ["@platforms//cpu:aarch64"],   # <- the key line
)
```

`--platforms=//x:linux_aarch64` sets the target platform. Resolution then only
accepts toolchains whose `target_compatible_with` is satisfied. The rule itself
contains no architecture logic at all.

## The two constraint attributes

| Attribute | Answers |
|-----------|---------|
| `target_compatible_with` | "What can this toolchain produce output **for**?" |
| `exec_compatible_with` | "What machine can this toolchain **run on**?" |

A real cross-compiler has both: an x86 binary (`exec_compatible_with` x86) that
emits ARM code (`target_compatible_with` aarch64).

## Real C++ cross-compilation

The same machinery, with more moving parts:

```bash
bazel build //src:server \
  --platforms=//platforms:linux_aarch64
```

You need a registered `cc_toolchain` whose `target_compatible_with` is aarch64,
typically from a module that packages a real cross-compiler
(`toolchains_llvm`, a vendor SDK, or a hand-written `cc_toolchain_config` -
sample 168).

Everything else is automatic:

- `cfg = "exec"` tools are built for **your** machine and run normally
- Target-configuration deps are built for ARM
- Output paths differ, so both architectures cache side by side

## Why `cfg = "exec"` finally matters

This is the build where forgetting `cfg = "exec"` (sample 122) breaks. Your
code generator gets built for ARM, Bazel tries to run it on x86, and the build
fails with `Exec format error`.

## Checking what you got

```bash
bazel cquery $X:arch --platforms=$X:linux_armv7 --output=jsonproto | head -30
bazel build $X:arch --toolchain_resolution_debug='.*codegen_type.*'
```

## Key takeaway

Cross-compilation is toolchain resolution driven by `--platforms`. Rules stay
architecture-agnostic; toolchains carry the differences.
