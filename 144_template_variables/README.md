# 144 - Custom Make Variables

**Concepts:** `TemplateVariableInfo`, the `toolchains` attribute

## Run it

```bash
bazel build //144_template_variables:manifest
cat bazel-bin/144_template_variables/manifest.txt

bazel run //144_template_variables:version
```

## Defining variables

```python
def _impl(ctx):
    return [platform_common.TemplateVariableInfo({
        "RELEASE_VERSION": ctx.attr.version,
        "RELEASE_CHANNEL": ctx.attr.channel,
    })]
```

## Using them

```python
genrule(
    name = "manifest",
    cmd = "echo $(RELEASE_VERSION) > $@",
    toolchains = [":vars"],      # <- brings the variables into scope
)
```

The `toolchains` attribute is doing double duty here: besides toolchain
resolution, it is the mechanism for importing Make variables from a target.
This is the same mechanism that gives you `$(CC)` from
`@bazel_tools//tools/cpp:current_cc_toolchain` (sample 038).

## Why this beats `--define`

| | `--define=VERSION=4.2.0` | `TemplateVariableInfo` |
|---|--------------------------|------------------------|
| Namespace | Global and flat | A target with a label |
| Default | None - fails if unset | Defined in the BUILD file |
| Visibility | Everywhere | Only targets that opt in |
| Several sets | Impossible | One target per set |
| Discoverable | No | `bazel query --output=build` |

You can have `:release_vars` and `:debug_vars` and pick per target. With
`--define` there is one global `VERSION` for the whole build.

## Where it fits

Real uses: version strings, vendor branding, SDK paths, sysroot locations,
toolchain binary paths. Anything that is (a) a plain string, (b) needed inside
a command line, and (c) varies by build configuration or target.

For values that need to be computed, or that are not strings, a normal
provider (sample 114) is the better tool.

## Combining with select()

```python
release_vars(
    name = "vars",
    version = select({
        ":nightly": "0.0.0-nightly",
        "//conditions:default": "4.2.0",
    }),
)
```

The variable's value then follows the configuration.

## Key takeaway

`TemplateVariableInfo` plus `toolchains = [...]` gives you scoped, defaulted,
discoverable Make variables - everything `--define` lacks.
