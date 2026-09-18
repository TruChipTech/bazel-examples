# 014 - glob Excludes

**Concepts:** `exclude`, separating tests from sources

## Run it

```bash
bazel test //014_glob_excludes:core_test
bazel query 'labels(srcs, //014_glob_excludes:lib)'
```

Note that `experimental_draft.py` - which is not even valid Python - never
appears. It is on disk, but it is not in the build graph, so Bazel never looks
at it.

## The idiom

```python
srcs = glob(["**/*.py"], exclude = ["**/*_test.py"])
```

This is so common that it is worth internalizing. Library sources and test
sources live side by side, but they must become different targets: tests depend
on the library, so putting a test file in the library would create a cycle or
ship test code to production.

## `exclude_directories`

Defaults to `1`, which is why globs never return directories. You rarely need
to change it.

## Key takeaway

`exclude` is subtractive and applied after the includes. Use it to keep tests,
generated files, and work-in-progress out of production targets.
