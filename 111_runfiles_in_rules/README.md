# 111 - Runfiles in Custom Rules

**Concepts:** `ctx.runfiles`, merging, `short_path`

## Run it

```bash
bazel run //111_runfiles_in_rules:wrapped -- extra args
```

## The bug this sample prevents

```python
# WRONG - the wrapper runs, but the wrapped binary loses its data
runfiles = ctx.runfiles(files = [ctx.file.config])

# RIGHT - merge the dependency's runfiles in
runfiles = ctx.runfiles(files = [ctx.file.config])
runfiles = runfiles.merge(ctx.attr.binary[DefaultInfo].default_runfiles)
```

Delete the `.merge(...)` line and rerun: the inner binary reports that it
cannot find `inner_data.txt`. The wrapper itself works fine, which is why this
bug survives until someone runs the wrapped program in anger.

## Building runfiles

```python
ctx.runfiles(files = [f1, f2])                 # specific files
ctx.runfiles(transitive_files = depset(...))   # a depset
ctx.runfiles(symlinks = {"path": file})        # custom layout
ctx.runfiles(root_symlinks = {"path": file})   # relative to runfiles root
```

## Merging

```python
rf = ctx.runfiles(files = [...])
rf = rf.merge(other_runfiles)                  # one
rf = rf.merge_all([a, b, c])                   # several - prefer this in a loop
```

`merge_all` is O(n); repeated `merge` in a loop is O(n²). For a rule with many
deps, always use `merge_all`.

## `default_runfiles` vs `data_runfiles`

```python
dep[DefaultInfo].default_runfiles   # what you almost always want
dep[DefaultInfo].data_runfiles      # legacy distinction, rarely needed
```

## `short_path` in generated scripts

```python
config = ctx.file.config.short_path      # "111_runfiles_in_rules/settings.conf"
```

A launcher executes *inside* the runfiles tree, so it must use runfiles-relative
paths. Using `.path` (the execroot path) produces a script that works during the
build and fails when run.

## The rule of thumb

**If your rule wraps, launches, or depends on an executable, merge its
runfiles.** There is no automatic propagation.

## Key takeaway

Runfiles are the runtime closure and they must be assembled explicitly.
`merge_all` plus `short_path` are the two things to get right.
