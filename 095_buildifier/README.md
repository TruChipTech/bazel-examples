# 095 - Formatting and Linting With buildifier

**Concepts:** `buildifier`, `buildozer`, CI formatting gates

## Run it

```bash
# Check formatting across the repo:
bazel run //095_buildifier:format_check

# Rewrite files in place:
bazel run //095_buildifier:format
```

## What buildifier does

1. **Formats.** Canonical indentation, line breaks, quote style.
2. **Sorts.** `deps`, `srcs` and similar lists are alphabetized; attributes are
   ordered conventionally (`name` first, then the rest).
3. **Lints.** Warns about real problems: unused `load()`s, `native.` calls in
   BUILD files, deprecated functions, missing `load()` statements.

Sorted `deps` matter more than they sound: they make diffs minimal and merge
conflicts rare. Two people adding a dependency to the same target will not
conflict if the list is sorted.

## The modes

| `mode` | Effect |
|--------|--------|
| `fix` | Rewrite files |
| `check` | Exit non-zero if changes are needed |
| `diff` | Print what would change |

| `lint_mode` | Effect |
|-------------|--------|
| `off` | No linting |
| `warn` | Report warnings |
| `fix` | Auto-fix what it can |

## The CI pattern

```yaml
- run: bazel run //:format_check
```

Or as a test, so it runs with everything else:

```python
buildifier_test(name = "format_test", srcs = glob(["**/BUILD.bazel"]), mode = "check")
```

## buildozer: scripted BUILD edits

buildifier's companion performs *programmatic* edits - invaluable for
repo-wide refactors:

```bash
buildozer 'add deps //new:dep' //services/...:*
buildozer 'remove deps //old:dep' //...:*
buildozer 'set visibility //visibility:public' //lib:mylib
buildozer 'new cc_library mylib' //some/pkg:__pkg__
```

Bazel's own error messages frequently print the exact buildozer command to run,
as sample 076 showed.

## Setup

```python
# MODULE.bazel
bazel_dep(name = "buildifier_prebuilt", version = "8.2.0.2", dev_dependency = True)
```

`dev_dependency = True` keeps it out of anyone who depends on your module.

## Key takeaway

Format automatically and enforce it in CI. Sorted, canonical BUILD files remove
an entire category of review comments and merge conflicts.
