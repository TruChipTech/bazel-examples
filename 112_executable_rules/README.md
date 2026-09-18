# 112 - Executable Rules

**Concepts:** `executable = True`, `bazel run`, custom tooling

## Run it

```bash
bazel run //112_executable_rules:deploy
bazel run //112_executable_rules:deploy -- --dry-run
```

## The two halves

```python
def _impl(ctx):
    return [DefaultInfo(executable = script)]   # 1. which file to run

task_runner = rule(
    implementation = _impl,
    executable = True,                          # 2. declare the rule runnable
)
```

Omitting either one produces a confusing error. `executable = True` without
`DefaultInfo(executable = ...)` fails at analysis; the reverse makes the target
build but not run.

## Why write an executable rule?

Because it turns an operational task into a build target, which means it gets:

- **Declared inputs.** The tool it runs, its config, its data - all tracked.
- **A stable label.** `bazel run //:deploy` works from anywhere in the repo.
- **Composition.** Other rules can depend on it as a `tool`.
- **Configuration.** It can read `select()`ed attributes and build settings.

This is how repos replace `scripts/deploy.sh` with something that cannot
silently reference a file nobody declared.

## The generated launcher pattern

Most executable rules follow the same shape:

1. Generate a script with `ctx.actions.write(is_executable = True)` or
   `ctx.actions.expand_template(is_executable = True)`.
2. Reference other files by `short_path` (runfiles-relative).
3. Assemble runfiles, merging dependencies' runfiles.
4. Return `DefaultInfo(executable = ..., runfiles = ...)`.

`py_binary`, `java_binary` and `sh_binary` all work this way.

## `bazel run` specifics

```bash
bazel run //pkg:target -- --flag value   # args after --
```

Bazel sets `BUILD_WORKING_DIRECTORY` to the directory you invoked it from,
since the program itself runs in the runfiles tree. Read it when the tool needs
to act on the user's current directory.

## Related: `test = True`

Replacing `executable = True` with `test = True` makes a test rule instead -
see sample 113.

## Key takeaway

`executable = True` plus `DefaultInfo(executable = ...)`. Executable rules are
how operational scripts join the build graph.
