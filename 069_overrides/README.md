# 069 - The Override Family

**Concepts:** `single_version_override`, `archive_override`, `git_override`

## Run it

```bash
bazel build //069_overrides:pinned_proof
cat bazel-bin/069_overrides/pinned.txt

bazel mod explain rules_license
```

## The overrides

All of them go in the **root** `MODULE.bazel` and all of them are ignored when
your module is consumed by someone else.

### `single_version_override` - pin a version

```python
single_version_override(module_name = "rules_license", version = "1.0.0")
```

Forces exactly this version regardless of what Minimal Version Selection would
pick. Also takes `patches` and `patch_strip` to apply local fixes:

```python
single_version_override(
    module_name = "rules_foo",
    version = "1.2.0",
    patches = ["//patches:fix_windows.patch"],
    patch_strip = 1,
)
```

This is the standard way to carry an upstream fix while you wait for a release.

### `archive_override` - fetch from a URL instead of the registry

```python
archive_override(
    module_name = "rules_foo",
    urls = ["https://github.com/org/rules_foo/archive/abc123.tar.gz"],
    strip_prefix = "rules_foo-abc123",
    integrity = "sha256-...",
)
```

Use it for a module that is not published, or to test an unreleased commit.

### `git_override` - fetch from a git repository

```python
git_override(
    module_name = "rules_foo",
    remote = "https://github.com/org/rules_foo.git",
    commit = "abc123def456",
)
```

Convenient for development; slower than `archive_override`, and it requires git
on every build machine. Prefer `archive_override` in CI.

### `local_path_override` - use a directory on disk

Covered in sample 068.

### `multiple_version_override` - allow two versions at once

```python
multiple_version_override(module_name = "rules_foo", versions = ["1.0.0", "2.0.0"])
```

A last resort for genuinely incompatible consumers. Both versions are built,
and each dependent gets the one it asked for.

## Minimal Version Selection, briefly

Given `A` needs `foo@1.0` and `B` needs `foo@1.5`, bzlmod selects
**`foo@1.5`** - the lowest version that satisfies everyone, not the newest
available. This makes builds reproducible: adding a dependency cannot silently
upgrade an unrelated module.

An override is how you opt out of that computation deliberately.

## Key takeaway

Overrides are root-module-only escape hatches. Reach for
`single_version_override` with `patches` before forking a dependency.
