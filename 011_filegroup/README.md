# 011 - filegroup: Naming a Set of Files

**Concepts:** `filegroup`, composition, indirection

## Run it

```bash
bazel build //011_filegroup:asset_manifest
cat bazel-bin/011_filegroup/manifest.txt
```

## Why not just list the files?

Indirection. When ten targets need the same asset set, they all say
`:web_assets`. Adding a file means editing one line instead of ten.

filegroup also crosses package boundaries safely: another package can depend on
`//011_filegroup:web_assets` without knowing or caring which files
are inside, and without needing visibility on each individual file.

## filegroup does nothing at build time

It produces no actions. It is purely a naming and grouping construct, resolved
during the loading phase. That makes it free.

## Common uses

- Bundling static assets (this sample)
- Grouping test fixtures for reuse across several tests
- Exposing a subset of a package's files to other packages
- Wrapping a `glob()` so the glob is written once (sample 013)

## Key takeaway

`filegroup` is the answer to "how do I refer to these N files as one thing".
