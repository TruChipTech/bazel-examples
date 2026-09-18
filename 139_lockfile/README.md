# 139 - The Lockfile and Reproducibility

**Concepts:** `MODULE.bazel.lock`, `--lockfile_mode`, `bazel mod tidy`

## Look at it

```bash
ls -la MODULE.bazel.lock
head -40 MODULE.bazel.lock

bazel mod deps --lockfile_mode=update
```

## What the lockfile records

- The exact **version** selected for every module
- The **integrity hashes** of registry metadata and archives
- The **outputs of module extensions** - which repositories they created and
  with what attributes
- The **registry URLs** used

It is the bzlmod equivalent of `package-lock.json` or `Cargo.lock`.

## Commit it

Without the lockfile, two developers resolving at different times can get
different module versions - the registry moved underneath them. With it, the
resolution is pinned until someone deliberately updates it.

## `--lockfile_mode`

| Mode | Behavior |
|------|----------|
| `update` (default) | Use it; update it when `MODULE.bazel` changes |
| `refresh` | Re-check mutable data (registry contents) periodically |
| `error` | **Fail** if the lockfile is out of date |
| `off` | Ignore it entirely |

The CI pattern:

```bash
bazel test //... --lockfile_mode=error
```

CI then fails when someone edits `MODULE.bazel` without committing the updated
lockfile - which is exactly the review signal you want, since a dependency
change should be visible in the diff.

## Extensions and the lockfile

An extension's result is recorded unless it declared itself reproducible:

```python
return module_ctx.extension_metadata(reproducible = True)
```

`reproducible = True` means "the output is a pure function of the tags", so
there is nothing to lock. If the extension reads the environment, the clock, or
the network, it is **not** reproducible and must not claim to be - otherwise
the lockfile silently fails to capture a real source of variance.

## Keeping `MODULE.bazel` tidy

```bash
bazel mod tidy
```

Adds missing `use_repo()` calls, removes unused ones, and sorts them. Run it
after changing extension usage; it is the fastest fix for
`No repository visible as '@x'`.

## Merge conflicts

The lockfile conflicts often, because almost any dependency change touches it.
Resolve by regenerating rather than hand-editing:

```bash
git checkout --theirs MODULE.bazel.lock   # or --ours
bazel mod deps --lockfile_mode=update
git add MODULE.bazel.lock
```

## Key takeaway

Commit the lockfile, enforce it in CI with `--lockfile_mode=error`, regenerate
on conflict, and be honest about `reproducible`.
