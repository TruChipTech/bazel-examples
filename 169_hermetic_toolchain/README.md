# 169 - Hermetic Toolchains

**Concepts:** removing the host compiler from the build

## The problem with the default

By default, `rules_cc` auto-configures a toolchain from **whatever compiler is
on your PATH**. That means:

- Developer A has GCC 11, developer B has GCC 13, CI has Clang 17
- All three produce different output from the same source
- All three compute **different cache keys**, so the remote cache never hits
- A compiler upgrade on one machine silently changes results

This repository is a live example: its `.bazelrc` contains

```
build --repo_env=CC=/usr/bin/gcc
build --repo_env=CXX=/usr/bin/g++
```

because a `ccache` shim on the host broke sandboxed compilation. That is a
host-configuration detail leaking into the build - exactly what a hermetic
toolchain removes.

## The fix: a downloaded toolchain

```python
# MODULE.bazel
bazel_dep(name = "toolchains_llvm", version = "1.4.0")

llvm = use_extension("@toolchains_llvm//toolchain/extensions:llvm.bzl", "llvm")
llvm.toolchain(llvm_version = "17.0.6")
use_repo(llvm, "llvm_toolchain")

register_toolchains("@llvm_toolchain//:all")
```

Now every machine downloads and uses **the same Clang 17.0.6**. The compiler is
an input to the build, pinned like any other dependency.

## Java, already hermetic here

```
build --java_runtime_version=remotejdk_21
build --tool_java_runtime_version=remotejdk_21
```

This repo does this because there is no local JDK - but it is the right setting
regardless. `local_jdk` makes the build depend on whatever the machine has.

## Python

```python
bazel_dep(name = "rules_python", version = "1.7.0")

python = use_extension("@rules_python//python/extensions:python.bzl", "python")
python.toolchain(python_version = "3.12")
use_repo(python, "python_3_12")
```

Without this, `py_binary` uses the system interpreter and your build depends on
the OS's Python version.

## What you gain

| Without | With |
|---------|------|
| "Works on my machine" | Identical results everywhere |
| Near-zero remote cache hits | Shared cache actually shares |
| Remote execution fails | Containers do not need a preinstalled compiler |
| Old commits stop building | Any commit rebuilds, years later |
| OS upgrade breaks the build | OS is irrelevant |

## What it costs

- A one-time download per machine (cached afterwards)
- Larger `MODULE.bazel.lock`
- Occasional friction when you genuinely want the system compiler

## The sysroot question

A hermetic *compiler* still links against the host's glibc unless you also
provide a **sysroot**. For full hermeticity, toolchain modules let you specify
one:

```python
llvm.sysroot(targets = ["linux-x86_64"], label = "@sysroot_linux_x86_64//:sysroot")
```

Most teams stop at a hermetic compiler; a hermetic sysroot matters when you
must run on older distributions than you build on.

## Key takeaway

Pin the compiler like any other dependency. It is the single highest-impact
change for remote cache hit rates and cross-machine consistency.
