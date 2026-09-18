# 125 - Registering Toolchains

**Concepts:** `register_toolchains`, resolution order

## Run it

```bash
R=//125_toolchain_registration

# No --extra_toolchains: resolution uses the REGISTERED toolchains.
bazel build $R:auto_compiled
cat bazel-bin/125_toolchain_registration/auto_compiled.out
```

It uses the **fast** compiler, because `//MODULE.bazel` registers that one
first.

## Registering

```python
# MODULE.bazel
register_toolchains(
    "//125_toolchain_registration:fast_compiler_toolchain",
    "//125_toolchain_registration:reference_compiler_toolchain",
)
```

You can also register a whole package:

```python
register_toolchains("//toolchains:all")
```

## Resolution order

For each toolchain type, Bazel considers candidates in this order:

1. `--extra_toolchains` (highest priority, and **last-specified wins**)
2. `register_toolchains()` from the **root** module, in order
3. `register_toolchains()` from dependency modules

and picks the **first** whose `exec_compatible_with` and
`target_compatible_with` constraints are satisfied by the current execution and
target platforms.

Because first-match wins, **order is your priority mechanism**. Put the
preferred implementation first.

## Overriding for one build

```bash
bazel build //x:y --extra_toolchains=//toolchains:reference_compiler_toolchain
```

Useful for testing an alternate toolchain without editing `MODULE.bazel`. Pin
it in `.bazelrc` under a `--config` name if the team needs it regularly.

## How rule sets use this

When you add `bazel_dep(name = "rules_go", ...)`, its own `MODULE.bazel`
registers Go toolchains. That is why `go_binary` works immediately with no
configuration - the module registered a toolchain for your platform on your
behalf.

## Debugging

```bash
bazel build //x:y --toolchain_resolution_debug='.*'
```

See sample 126.

## Key takeaway

`register_toolchains()` in `MODULE.bazel` makes toolchains available
repo-wide. First compatible match wins, so order expresses preference.

## Gotcha: registered toolchains are analyzed in every build

A registered `toolchain()` is evaluated on **every** build, whether or not
anything uses it. So everything it references must be visible from the package
containing the `toolchain()` rule:

```
ERROR: in toolchain rule //125_toolchain_registration:fast_compiler_toolchain:
Visibility error: target '//124_custom_toolchain:compiler_type' is not visible
```

This surfaces as a failure on a completely unrelated target, which makes it
confusing the first time. Toolchain types and toolchain implementations are
conventionally `//visibility:public` for exactly this reason.
