# 038 - Make Variables

**Concepts:** `$(VAR)`, predefined variables, `toolchains`

## Run it

```bash
bazel build //038_make_variables:all
cat bazel-bin/038_make_variables/vars.txt
cat bazel-bin/038_make_variables/cc.txt

# The values change with the configuration:
bazel build -c opt //038_make_variables:show_vars
cat bazel-bin/038_make_variables/vars.txt
```

## The predefined set

| Variable | Value |
|----------|-------|
| `$(COMPILATION_MODE)` | `fastbuild`, `dbg` or `opt` |
| `$(TARGET_CPU)` | The target CPU, e.g. `k8` |
| `$(BINDIR)` | The `bazel-bin` path for this configuration |
| `$(GENDIR)` | The generated-files root |
| `$(SRCS)` / `$(OUTS)` | genrule inputs / outputs |
| `$@` | The single output (genrule only) |
| `$<` | The single input (genrule only) |

## Toolchain-provided variables

Adding `toolchains = ["@bazel_tools//tools/cpp:current_cc_toolchain"]` puts
`$(CC)`, `$(AR)`, `$(NM)` and others in scope. This is the correct way to
invoke "the compiler Bazel decided to use" rather than whatever `cc` resolves
to on PATH.

## Escaping

Bazel consumes one `$` before the shell sees the command:

```python
cmd = "echo $$HOME"      # shell sees: echo $HOME
cmd = "echo $(BINDIR)"   # Bazel substitutes, shell sees the path
```

Forgetting to double the `$` is the classic genrule bug - the shell receives an
empty string where you expected a variable.

## Custom Make variables

A rule can define its own with `TemplateVariableInfo`; sample 144 shows how.

## Key takeaway

Make variables let a command adapt to the configuration without a `select()`.
Remember `$$` for literal dollars.
