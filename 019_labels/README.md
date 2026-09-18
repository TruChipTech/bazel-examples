# 019 - Label Syntax in Depth

**Concepts:** labels, wildcards, external repo references

## Try the wildcards

```bash
bazel query //019_labels:all      # targets in this package
bazel query //019_labels/...      # this package and below
bazel query //...                             # every target in the workspace
```

## The forms

| Form | Means |
|------|-------|
| `//pkg/sub:name` | Absolute label - identical meaning everywhere |
| `//pkg/sub` | Shorthand for `//pkg/sub:sub` |
| `:name` | Target `name` in the current package |
| `name` | Same as `:name` when used inside an attribute |
| `@repo//pkg:name` | Target in the external repository `repo` |
| `//pkg:file.txt` | A source file, if the package exports it |

## `:all` vs `...`

- `:all` - every target in exactly one package.
- `/...` - every target in a package **and all packages below it**.

`...` is a package wildcard, not a filesystem glob. `//foo/...` expands by
walking the tree looking for BUILD files.

## Prefer absolute labels in shared code

`:helper` breaks the moment someone copies the line into another package.
`//path/to:helper` never does. Relative labels are fine for genuinely local
references; absolute labels are the safe default everywhere else.

## Key takeaway

A label is a global, location-independent name. That property is what makes
`bazel build //...` and remote caching possible.
