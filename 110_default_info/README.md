# 110 - DefaultInfo

**Concepts:** `files`, `runfiles`, `executable`, default outputs

## Run it

```bash
bazel build //110_default_info:assets
cat bazel-bin/110_default_info/assets.bundle

bazel run //110_default_info:show
```

## The four fields

```python
DefaultInfo(
    files = depset([...]),          # default outputs
    runfiles = ctx.runfiles(...),   # runtime files for dependents
    executable = some_file,         # what `bazel run` executes
    data_runfiles = ...,            # legacy; prefer `runfiles`
)
```

## `files` vs `runfiles` - the distinction that matters

| | `files` | `runfiles` |
|---|---------|-----------|
| Answers | "What does building this produce?" | "What does this need at runtime?" |
| Used by | `bazel build`, `srcs` of a consumer | `data` of a consumer |
| Typical content | Compiled artifacts | Config, assets, shared libs |

They are frequently different. A library's `files` is its `.a` archive; its
`runfiles` might be a data file the library loads at startup. This sample puts
the source files and the bundle in runfiles but both generated files in `files`.

## Returning nothing is an error

Every rule implementation must return a list of providers. Returning `[]` is
legal but means the target produces nothing - `bazel build` on it succeeds and
does nothing, which is almost always a bug.

## Runfiles merge, they do not replace

```python
runfiles = ctx.runfiles(files = [f]).merge_all([
    dep[DefaultInfo].default_runfiles
    for dep in ctx.attr.deps
])
```

A rule with dependencies must merge their runfiles or the dependencies' data
files silently disappear. Sample 111 covers this.

## Inspecting from the command line

```bash
bazel cquery //110_default_info:assets --output=files
```

## Key takeaway

`DefaultInfo.files` is the build output; `DefaultInfo.runfiles` is the runtime
closure. Deciding what belongs in each is a real design decision, not a
formality.
