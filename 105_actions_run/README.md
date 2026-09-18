# 105 - ctx.actions.run

**Concepts:** `run`, `Args`, `cfg = "exec"`, mnemonics

## Run it

```bash
bazel build //105_actions_run:frequencies
cat bazel-bin/105_actions_run/frequencies.txt

# See the action Bazel created:
bazel aquery 'mnemonic("WordFreq", //105_actions_run:frequencies)'
```

## The anatomy of an action

```python
ctx.actions.run(
    inputs = ctx.files.srcs,        # everything the tool may read
    outputs = [out],                # everything it must produce
    executable = ctx.executable.tool,
    arguments = [args],
    mnemonic = "WordFreq",
    progress_message = "Counting words for %s" % ctx.label,
)
```

Inputs and outputs are the **contract**. Bazel hashes the inputs plus the
command line to form a cache key. Read an undeclared file and the sandbox
denies it; fail to write a declared output and the action fails.

## `cfg = "exec"` on tool attributes

```python
"tool": attr.label(cfg = "exec", executable = True, default = Label("//pkg:tool")),
```

`exec` means "build this for the machine executing the build". Without it, the
tool is built for the *target* platform - so when you cross-compile for ARM,
the build tries to run an ARM binary on your x86 machine.

On a normal same-machine build the bug is invisible. It only appears the first
time someone cross-compiles, which is why it is worth getting right from the
start.

## `ctx.actions.args()`

```python
args = ctx.actions.args()
args.add(out)                  # a File becomes its exec path
args.add_all(ctx.files.srcs)   # expand a list
args.add("--flag", value)
args.add_joined(files, join_with = ",")
```

`Args` is lazy: the command line is materialized only if the action actually
runs, and it can automatically spill to a parameter file when it grows too long
for the OS limit (sample 146). A plain Python list does neither.

## `mnemonic` matters more than it looks

It is the action's type name. It appears in build output, and it is the handle
for:

```bash
bazel aquery 'mnemonic("WordFreq", //...)'
bazel build //... --strategy=WordFreq=local
bazel build //... --modify_execution_info=WordFreq=+no-remote
```

Pick a short CamelCase name and keep it stable.

## `run` vs `run_shell`

Use `run` when you are invoking one program with arguments - no shell, better
portability, cleaner quoting. Use `run_shell` (sample 106) only when you
genuinely need shell features.

## Key takeaway

`ctx.actions.run` executes a declared tool with declared inputs and outputs.
`cfg = "exec"` on the tool attribute is not optional.
