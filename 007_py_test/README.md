# 007 - Python Tests

**Concepts:** `py_test`, `unittest`, `size`

## Run it

```bash
bazel test //007_py_test:validators_test --test_output=all
```

## `unittest` needs no special support

`py_test` runs the file as a program. Because `unittest.main()` exits non-zero
when a test fails, the Bazel contract is satisfied without any plugin. The same
is true of `pytest`, which just needs to be declared as a dependency.

## Why `size` matters

`size` is not documentation - it sets the timeout and tells Bazel roughly how
many resources to reserve, which affects how aggressively tests run in
parallel. Marking a slow test `small` makes it flaky under load; marking a fast
test `enormous` wastes scheduling capacity.

Override the timeout independently when the size is right but the duration is
unusual:

```python
py_test(name = "...", size = "small", timeout = "moderate")
```

## Key takeaway

Choose `size` honestly. It is the main lever Bazel has for scheduling a large
test suite without thrashing.
