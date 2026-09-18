# 016 - Package-Level Defaults

**Concepts:** `package()`, `default_visibility`, inheritance

## Inspect it

```bash
bazel query --output=build //016_default_visibility:a
```

The output shows the effective `visibility` even though the target never set it.

## Rules for `package()`

- It must appear **before** any target in the file.
- It may appear **once** per BUILD file.
- It affects only this file, never subdirectories. (Sample 049 covers
  `REPO.bazel` / `default_visibility` inheritance patterns for whole trees.)

## Other useful package-level defaults

```python
package(
    default_visibility = ["//visibility:public"],
    default_testonly = True,          # everything here is test-only code
    default_applicable_licenses = ["//:license"],
)
```

## A word of caution

`default_visibility = ["//visibility:public"]` is convenient and very common,
but it switches off the enforcement from sample 015 for the whole package. In
a library package that is fine; in a package holding internal implementation
details, prefer listing the specific consumers.

## Key takeaway

Package defaults reduce repetition. Individual targets always win over the
default, so you can open a package broadly and still lock down specific targets.
