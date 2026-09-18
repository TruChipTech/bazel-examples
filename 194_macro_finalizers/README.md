# 194 - Symbolic Macro Finalizers

**Concepts:** `finalizer = True`, `native.existing_rules()`

## Run it

```bash
bazel test //194_macro_finalizers:coverage_guard --test_output=all
bazel query //194_macro_finalizers:all
```

The guard sees `:alpha` and `:alpha_test` even though the `coverage_guard()`
call appears **before** them in the BUILD file.

## What a finalizer is

```python
coverage_guard = macro(
    implementation = _impl,
    finalizer = True,
)
```

A finalizer is a symbolic macro that Bazel expands **after every other macro
and target in the package**. That ordering guarantee is what makes
`native.existing_rules()` meaningful inside it - it sees the complete package.

## Why this needed a new feature

A legacy macro can call `native.existing_rules()`, but it only sees what was
declared *above it*, so the result depends on where the call sits in the file.
That made whole-package analysis fragile and order-dependent.

Symbolic macros forbid `existing_rules()` entirely - **except** in finalizers,
where the ordering is well-defined.

## What finalizers are good for

| Use | Example |
|-----|---------|
| Package-wide policy | "Every library must have a test" (this sample) |
| Aggregation | A `test_suite` containing every test in the package |
| Consistency checks | "Every service target declares an owner tag" |
| Generated indexes | A manifest of everything in the package |

```python
def _auto_suite_impl(name, visibility, **kwargs):
    tests = [
        ":" + n
        for n, attrs in native.existing_rules().items()
        if attrs.get("kind", "").endswith("_test")
    ]
    native.test_suite(name = name, tests = tests)

auto_suite = macro(implementation = _auto_suite_impl, finalizer = True)
```

That is a genuinely useful five-line finalizer: a `test_suite` that can never
go stale.

## The constraints

- Several finalizers in one package run in **unspecified order** relative to
  each other, so they must not depend on one another.
- A finalizer cannot see targets in *other* packages - only its own.
- Everything it creates must still follow symbolic-macro naming rules
  (`name` or `name + "_suffix"`).

## Ordering is not source order

`coverage_guard()` is written first and expands last. If that seems confusing,
it is the point: finalizers are defined by **phase**, not by position, so
moving the call does not change behavior.

## Key takeaway

`finalizer = True` is the only sanctioned way to reason about a whole package.
Use it for policy checks and auto-generated suites; keep finalizers independent
of each other.

## Gotcha: finalizers are symbolic macros, so attributes are strict

```python
coverage_guard(name = "coverage_guard", size = "small")
```

```
Error: no such attribute 'size' in 'coverage_guard' macro
```

A symbolic macro only accepts attributes it declares (sample 052). Anything a
caller should be able to pass - even a standard one like `size` - must appear
in `attrs`:

```python
attrs = {"size": attr.string(default = "small", configurable = False)}
```

This is stricter than a legacy macro, which would silently forward anything
through `**kwargs`, and it is the point: the macro's interface is now
inspectable.
