# 192 - Loading Phase Performance

**Concepts:** glob cost, package granularity, `.bazelignore`

## Measure the loading phase

```bash
time bazel query //... > /dev/null        # loading only
time bazel build --nobuild //...          # loading + analysis
```

If the first is slow, the problem is package loading: globs, BUILD file count,
or directories Bazel should not be scanning.

## Globs are filesystem traversals

```python
glob(["**/*.py"])          # walks the ENTIRE package subtree
glob(["src/*.py"])         # one directory
```

A `**` glob in a package containing a large subtree is re-evaluated whenever
the package is reloaded. In a repo with hundreds of such packages, this is
measurable.

Rules that help:

| Practice | Why |
|----------|-----|
| Prefer `src/*.py` over `**/*.py` | Bounded traversal |
| `allow_empty = False` | Catches typos that would otherwise be silent |
| Explicit file lists in hot packages | Zero traversal, and readable |
| Avoid globbing generated directories | They may not exist yet |

## Globs stop at package boundaries

This sample has `wide/a/BUILD.bazel` and `wide/b/BUILD.bazel`, so a
`glob(["**/*.py"])` at the top level matches **nothing** from those
directories - they belong to other packages.

That is usually what you want, and it is also a common source of "why is my
file not in the target?".

## `.bazelignore` for directories Bazel must not scan

```
node_modules
.git
build_output
068_local_path_override/greeting_lib
```

Without this, Bazel traverses those trees looking for BUILD files on every
loading pass. For a `node_modules` directory that is tens of thousands of
files, on every build.

This repository's `.bazelignore` excludes a nested module for exactly this
reason.

## Package granularity

| Too few packages | Too many packages |
|------------------|-------------------|
| Huge globs | Loading overhead per package |
| Coarse caching - one edit invalidates a lot | BUILD file sprawl |
| Poor parallelism | Harder to navigate |

The practical guideline: **one package per cohesive unit**, and let target
granularity (sample 018) rather than package granularity drive caching.

## BUILD file evaluation is cached

Bazel caches loaded packages in the server's memory, so a second build does not
re-read them. This is another reason not to `bazel shutdown` (sample 191).

Changing any `.bzl` file that a package loads invalidates that package - so a
widely-loaded `defs.bzl` is a loading-phase hot spot. Keep constants in a
separate, rarely-changing file (sample 053).

## Key takeaway

Narrow your globs, use `.bazelignore` aggressively, and measure with
`bazel query //...` before optimizing anything else.
