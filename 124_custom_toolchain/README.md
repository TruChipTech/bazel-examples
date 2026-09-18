# 124 - A Toolchain That Carries a Tool

**Concepts:** `files_to_run`, tools in toolchains

## Run it

```bash
C=//124_custom_toolchain

bazel build $C:hello_compiled --extra_toolchains=$C:fast_toolchain
cat bazel-bin/124_custom_toolchain/hello_compiled.out

bazel build $C:hello_compiled --extra_toolchains=$C:reference_toolchain
cat bazel-bin/124_custom_toolchain/hello_compiled.out
```

Two completely different compilers, one unchanged `mini_compile` target.

## Carrying an executable

```python
def _compiler_toolchain_impl(ctx):
    return [platform_common.ToolchainInfo(
        compiler = ctx.executable.compiler,
        compiler_files = ctx.attr.compiler[DefaultInfo].files_to_run,
        flavor = ctx.attr.flavor,
    )]
```

Two things are needed:

| Field | What it is |
|-------|-----------|
| `ctx.executable.compiler` | The `File` to execute |
| `files_to_run` | The executable **plus its runfiles** |

## `files_to_run` is the part people forget

```python
ctx.actions.run(
    executable = toolchain.compiler,
    tools = [toolchain.compiler_files],    # <- required
    ...
)
```

A `py_binary` is a launcher script that needs its runfiles (the interpreter
wiring, the actual `.py` files). Passing only the executable file produces:

```
python: can't open file '...': No such file or directory
```

`files_to_run` is a `FilesToRunProvider` that bundles the executable with
everything it needs; putting it in `tools` stages all of it.

## Why the consumer stays simple

`mini_compile` contains no reference to `fast` or `reference`. It asks for a
toolchain type and uses whatever it gets. Adding a third compiler means adding
a `compiler_toolchain` + `toolchain` pair - no change to the rule or to any
target using it.

## The exec configuration

```python
"compiler": attr.label(cfg = "exec", executable = True),
```

Toolchain tools always run on the execution platform. This is the attribute
from sample 122, and here it is genuinely load-bearing.

## Key takeaway

Put the tool *and* its `files_to_run` in the `ToolchainInfo`, and pass the
latter to `tools`. Consumers then never name a specific implementation.
