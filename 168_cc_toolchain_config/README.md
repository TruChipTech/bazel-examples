# 168 - Writing a C++ Toolchain

**Concepts:** `cc_toolchain`, `cc_common.create_cc_toolchain_config_info`, features

## The three pieces

```python
# 1. The config rule: describes tool paths, flags and features
cc_toolchain_config(name = "my_config", ...)

# 2. The toolchain: binds the config to the tool files
cc_toolchain(
    name = "my_cc_toolchain",
    toolchain_config = ":my_config",
    all_files = ":all_tool_files",
    compiler_files = ":compiler_files",
    linker_files = ":linker_files",
    ...
)

# 3. The toolchain() binding, as in every toolchain (sample 123)
toolchain(
    name = "cc_toolchain_for_linux_arm64",
    toolchain = ":my_cc_toolchain",
    toolchain_type = "@bazel_tools//tools/cpp:toolchain_type",
    target_compatible_with = ["@platforms//os:linux", "@platforms//cpu:aarch64"],
)
```

## The config rule

```python
load("@rules_cc//cc:action_names.bzl", "ACTION_NAMES")
load("@rules_cc//cc:cc_toolchain_config_lib.bzl",
     "feature", "flag_group", "flag_set", "tool_path")

def _impl(ctx):
    tool_paths = [
        tool_path(name = "gcc", path = "/opt/cross/bin/aarch64-linux-gnu-gcc"),
        tool_path(name = "ld", path = "/opt/cross/bin/aarch64-linux-gnu-ld"),
        tool_path(name = "ar", path = "/opt/cross/bin/aarch64-linux-gnu-ar"),
        tool_path(name = "cpp", path = "/opt/cross/bin/aarch64-linux-gnu-cpp"),
        tool_path(name = "nm", path = "/bin/false"),
        tool_path(name = "objdump", path = "/bin/false"),
        tool_path(name = "strip", path = "/bin/false"),
    ]

    default_flags = feature(
        name = "default_compile_flags",
        enabled = True,
        flag_sets = [flag_set(
            actions = [ACTION_NAMES.c_compile, ACTION_NAMES.cpp_compile],
            flag_groups = [flag_group(flags = ["-no-canonical-prefixes", "-Wall"])],
        )],
    )

    return cc_common.create_cc_toolchain_config_info(
        ctx = ctx,
        toolchain_identifier = "aarch64-toolchain",
        host_system_name = "local",
        target_system_name = "aarch64-linux-gnu",
        target_cpu = "aarch64",
        target_libc = "glibc",
        compiler = "gcc",
        abi_version = "unknown",
        abi_libc_version = "unknown",
        tool_paths = tool_paths,
        features = [default_flags],
        cxx_builtin_include_directories = ["/opt/cross/aarch64-linux-gnu/include"],
    )

cc_toolchain_config = rule(
    implementation = _impl,
    attrs = {},
    provides = [CcToolchainConfigInfo],
)
```

## Features are the flag system

A **feature** is a named, conditionally-enabled set of flags attached to
specific action types:

```python
feature(
    name = "opt",
    flag_sets = [flag_set(
        actions = [ACTION_NAMES.cpp_compile],
        flag_groups = [flag_group(flags = ["-O2", "-DNDEBUG"])],
    )],
)
```

Features can require or imply one another, and are toggled with
`--features=name` / `--features=-name` or the `features` attribute on a target
or package. This is the machinery behind `layering_check` (sample 167),
`parse_headers`, `thin_lto` and the rest.

`cxx_builtin_include_directories` is the one people get wrong: any system
include directory the compiler uses implicitly must be listed, or Bazel's
strict header checking rejects every system header.

## Do not write one unless you must

This is the most intricate corner of Bazel. Before writing one, check whether
an existing module already does it:

| Module | Provides |
|--------|----------|
| `toolchains_llvm` | Hermetic Clang/LLVM for several platforms |
| `rules_cc` auto-configuration | Wraps the local system compiler |
| Vendor SDK modules | Embedded and console toolchains |
| `bazel-embedded` | ARM bare-metal toolchains |

Sample 169 shows using one of these instead.

## Debugging

```bash
bazel build //x:y --toolchain_resolution_debug='.*cpp.*'
bazel build //x:y --subcommands          # see the actual compiler invocations
```

## Key takeaway

`cc_toolchain_config` describes tool paths plus features. Reach for an existing
toolchain module first; write your own only for genuinely bespoke hardware.
