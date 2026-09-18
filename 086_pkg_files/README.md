# 086 - Fine-Grained Packaging With pkg_files

**Concepts:** `pkg_files`, `pkg_attributes`, `pkg_mkdirs`, `strip_prefix`

## Run it

```bash
bazel build //086_pkg_files:app_package
tar tzvf bazel-bin/086_pkg_files/app_package.tar.gz
```

Note the permission column: scripts are `0755`, docs are `0644`, and the
runtime directories exist with mode `0750`.

## Why not just `pkg_tar(srcs = ...)`?

`pkg_tar` alone gives you no control over **mode, owner, or destination per
file**. Everything inherits the source file's permissions, which in a Bazel
build are not meaningful - outputs are typically `0555` or `0644` regardless of
intent.

For anything that will be installed on a real system, that matters: a shell
script that is not executable, or a data directory that is world-writable, is a
production bug.

## The mapping rules

| Rule | Purpose |
|------|---------|
| `pkg_files` | Files, with mode/owner/destination |
| `pkg_mkdirs` | Empty directories that must exist |
| `pkg_mklink` | Symlinks |
| `pkg_filegroup` | Group several mappings, optionally adding a prefix |

They all produce *mappings*, which `pkg_tar`, `pkg_zip`, `pkg_deb` and
`pkg_rpm` then consume. The same mappings can therefore feed a `.deb` and a
`.tar.gz` with no duplication.

## `strip_prefix` variants

```python
strip_prefix.from_pkg("scripts")   # relative to this package
strip_prefix.from_root("some/dir") # relative to the workspace root
strip_prefix.files_only()          # discard all directory structure
```

## Composing an installable layout

```python
pkg_filegroup(
    name = "everything",
    srcs = [":scripts", ":docs", ":config"],
    prefix = "/opt/demo",       # re-root the whole set
)
```

## Key takeaway

`pkg_files` separates *what goes where with which permissions* from *what
archive format*. Define the layout once, emit any number of package types.
