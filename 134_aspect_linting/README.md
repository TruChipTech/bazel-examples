# 134 - A Linting Aspect

**Concepts:** aspect + tool, incremental linting, report aggregation

## Run it

```bash
L=//134_aspect_linting

bazel build $L:lint_all
cat bazel-bin/134_aspect_linting/lint_all.summary

# Or ad hoc, over any target:
bazel build $L:messy_module \
  --aspects=//134_aspect_linting:lint.bzl%lint_aspect \
  --output_groups=lint
```

## Why linting is a natural fit for aspects

The alternative - "run the linter over the whole repo in CI" - re-lints
everything on every commit and has no idea what changed.

As an aspect, each file's lint result is a **build action**:

- Cached per file. Unchanged files are not re-linted.
- Parallel, like every other action.
- Remotely executable.
- Incremental. Touch one file, lint one file.

On a large repo this is the difference between a 10-minute lint job and a
2-second one.

## The linter is an implicit dependency of the aspect

```python
lint_aspect = aspect(
    implementation = _impl,
    attrs = {
        "_linter": attr.label(
            default = Label("//pkg:lint"),
            cfg = "exec",
            executable = True,
        ),
    },
)
```

Because it is a declared dependency, changing the linter's source re-lints
everything - correctly, since the rules changed.

## Report or block?

This linter always exits 0 and writes findings to a file. That makes lint
results **advisory**: the build succeeds and you read the report.

To make lint failures break the build, either:

1. Exit non-zero from the linter - the action fails, so the build fails.
2. Put the reports in the `_validation` output group (sample 120), so they run
   automatically on every build without blocking unrelated work.

Option 2 is usually the right one for a large repo: universal enforcement,
parallel execution, clear attribution.

## Applying it repo-wide

```bash
bazel build //... --aspects=//tools:lint.bzl%lint_aspect --output_groups=lint
```

Or wire it into `.bazelrc` so it is always on:

```
build --aspects=//tools:lint.bzl%lint_aspect
build --output_groups=+lint
```

## Key takeaway

An aspect turns linting into cached, parallel, incremental build actions.
Combine with the `_validation` output group to enforce it everywhere.
