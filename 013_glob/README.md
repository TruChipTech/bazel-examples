# 013 - glob: Matching Files by Pattern

**Concepts:** `glob()`, `**`, `allow_empty`

## Inspect it

```bash
# See exactly which files the glob expanded to:
bazel query 'labels(srcs, //013_glob:all_modules)'
```

## How glob works

`glob()` runs during the **loading phase** and returns a plain list of strings.
By the time any rule sees it, it is just a list - there is no dynamic behavior
at build time.

| Pattern | Matches |
|---------|---------|
| `src/*.py` | `.py` files directly in `src/` |
| `src/**/*.py` | `.py` files in `src/` and any subdirectory |
| `**/*.py` | `.py` files anywhere in this package |

## The two rules glob always obeys

1. **It never crosses a package boundary.** If `src/vendor/BUILD.bazel` exists,
   `src/**/*.py` silently stops at `src/vendor`. Those files belong to that
   package now.
2. **It never matches directories**, only files.

## Always consider `allow_empty = False`

```python
srcs = glob(["src/*.py"], allow_empty = False)
```

Without it, renaming `src/` to `source/` leaves you with a library that
compiles nothing and fails much later, somewhere unrelated.

## The tradeoff

Globs keep BUILD files short but make them *implicit*: you can no longer tell
what a target contains by reading it, and adding a file silently changes the
build graph. Large monorepos often ban globs for exactly this reason and
generate explicit lists with a tool instead.

## Key takeaway

`glob()` is loading-time convenience, not a runtime feature. Prefer
`allow_empty = False`.
