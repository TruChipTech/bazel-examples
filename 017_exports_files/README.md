# 017 - exports_files: Sharing Raw Files

**Concepts:** `exports_files`, source-file visibility

## Run it

```bash
bazel build //017_exports_files:legal_bundle
cat bazel-bin/017_exports_files/legal.txt
```

## The problem it solves

Source files have visibility too. By default a file is only usable inside its
own package. Referencing `//other/pkg:some_file.txt` from elsewhere fails with:

```
no such target '//other/pkg:some_file.txt'
```

`exports_files()` declares "these raw files may be referenced by label from
outside".

## exports_files vs filegroup

| | `exports_files` | `filegroup` |
|---|---|---|
| Refers to | Individual files, by their own name | A named set |
| Consumer writes | `//pkg:LICENSE.txt` | `//pkg:legal` |
| Best for | A handful of well-known files | Sets that change over time |

Use `exports_files` for stable, individually-meaningful files (a license, a
config template, a `.proto`). Use `filegroup` when the membership is the point.

## Key takeaway

Visibility applies to files, not just rules. `exports_files()` is how a package
publishes a file for others to name directly.
