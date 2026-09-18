# 185 - Unit Testing Starlark

**Concepts:** `unittest.bzl`, `asserts`, testing build logic

## Run it

```bash
bazel test //185_starlark_unit_tests:lib_tests --test_output=errors
bazel query //185_starlark_unit_tests:all
```

One `lib_test_suite(name = ...)` call expands into four test targets plus a
suite.

## The shape

```python
load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")

def _my_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, "expected", my_function("input"))
    return unittest.end(env)

my_test = unittest.make(_my_test_impl)

def my_test_suite(name):
    unittest.suite(name, my_test)
```

`unittest.make` turns the implementation into a real test **rule**;
`unittest.suite` instantiates each one and wraps them in a `test_suite`.

## The assertions

```python
asserts.equals(env, expected, actual)
asserts.equals(env, expected, actual, "a message shown on failure")
asserts.true(env, condition)
asserts.false(env, condition)
asserts.set_equals(env, expected_set, actual_set)
asserts.new_set_equals(env, expected, actual)
asserts.expect_failure(env, "expected error substring")   # analysistest only
```

Always pass the message for non-obvious assertions - a bare
`expected "1", got "0"` in a build log is hard to place.

## Why test build logic at all

Macros and helper functions are **code that everyone depends on**. A bug in
`normalize_target_name` produces wrong target names across the repo, and the
failure surfaces somewhere unrelated.

These tests are fast - they run entirely in the loading/analysis phase, with no
compilation - so there is no reason not to have them.

## What this can and cannot test

| | Testable with `unittest` |
|---|---|
| Pure Starlark functions | **Yes** - this sample |
| Macro-generated target names | Yes, via `native.existing_rules()` |
| Rule **implementations** | No - use `analysistest` (sample 186) |
| The contents of generated files | No - use `diff_test` (sample 087) |

## The `asserts.equals` argument order

```python
asserts.equals(env, expected, actual)
```

Expected first. Getting it backwards makes every failure message read
backwards, which wastes real debugging time.

## Key takeaway

`unittest.bzl` makes Starlark helpers testable in the loading phase. If a
`.bzl` function has a branch, it deserves a test.

## Aside: Starlark has no `while` and no recursion

```python
while "__" in out:          # ERROR: contains syntax errors
    out = out.replace("__", "_")
```

Both are banned so that loading always terminates and can be cached. The idiom
is a **bounded** `for` loop:

```python
for _ in range(10):
    if "__" not in out:
        break
    out = out.replace("__", "_")
```

Pick a bound you can justify, and make sure the code is correct if the bound is
reached. This restriction is a frequent surprise when porting Python helpers
into `.bzl` files - and a good reason to unit-test them.
