# 044 - Target Patterns on the Command Line

**Concepts:** `:all`, `...`, exclusion, `--build_tag_filters`

## Try them

```bash
P=//044_target_patterns

bazel build $P:top_a      # one target
bazel build $P:all        # every target in THIS package only
bazel build $P/...        # this package and every package below it
bazel build $P/sub/...    # just the sub tree

# Everything except one subtree (note the minus):
bazel build $P/... -- -$P/sub/deeper/...
```

## The patterns

| Pattern | Meaning |
|---------|---------|
| `//pkg:name` | Exactly one target |
| `//pkg:all` | All **rule** targets in that one package |
| `//pkg:*` | All targets **including source files** |
| `//pkg/...` | That package and all packages below |
| `//...` | Everything in the workspace |
| `-//pkg/...` | Exclude (must come after `--`) |

## `:all` vs `...`

`:all` stops at the package boundary. `...` recurses into subdirectories
looking for more BUILD files. `//044_target_patterns:all` builds
two targets; `//044_target_patterns/...` builds four.

## What the wildcards skip

`manual_only` is tagged `manual`, so `:all` and `...` skip it. Naming it
directly still works:

```bash
bazel build $P:manual_only
```

## Filtering by tag

```bash
bazel build //... --build_tag_filters=-slow
bazel test  //... --test_tag_filters=unit
```

## Key takeaway

`...` recurses, `:all` does not, and `manual` opts out of both.
