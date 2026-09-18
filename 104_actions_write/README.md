# 104 - ctx.actions.write

**Concepts:** `declare_file`, `write`, `short_path` vs `path`

## Run it

```bash
bazel build //104_actions_write:file_manifest
cat bazel-bin/104_actions_write/file_manifest.manifest

bazel run //104_actions_write:hello_script
```

## `write` runs no process

```python
ctx.actions.write(output = out, content = "...")
```

Bazel writes the bytes itself. There is no shell, no subprocess, no sandbox
setup - so it is dramatically cheaper than a `genrule` that echoes a string,
and it works identically on every platform.

Use it for: manifests, generated config, launcher scripts, flag files, anything
whose content you can compute in Starlark.

## `short_path` vs `path`

This distinction causes real bugs:

| Property | Value | Use it for |
|----------|-------|-----------|
| `f.path` | `bazel-out/k8-fastbuild/bin/pkg/file.txt` | **Action** command lines |
| `f.short_path` | `pkg/file.txt` | **Runfiles** lookups at runtime |
| `f.basename` | `file.txt` | Display |
| `f.dirname` | the directory part | Display |
| `f.extension` | `txt` | Dispatch on file type |

Rule of thumb: if the string goes into an action's arguments, use `path`. If a
program will look the file up in its runfiles, use `short_path`.

## Making a target runnable

```python
return [DefaultInfo(executable = script)]

generated_script = rule(..., executable = True)
```

Both halves are required: `executable = True` on the rule, and
`DefaultInfo(executable = ...)` in the implementation. Sample 112 covers this
and the runfiles that usually accompany it.

## `declare_file` naming

```python
ctx.actions.declare_file(ctx.label.name + ".txt")            # in the package dir
ctx.actions.declare_file("subdir/" + ctx.label.name + ".h")  # nested
```

Prefixing with `ctx.label.name` is the convention that keeps two targets in the
same package from colliding.

## Key takeaway

`ctx.actions.write` is the cheapest way to produce a file. Prefer it over a
genrule whenever the content is computable in Starlark.
