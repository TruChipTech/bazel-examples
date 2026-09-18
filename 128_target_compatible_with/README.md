# 128 - target_compatible_with: Platform-Incompatible Targets

**Concepts:** `target_compatible_with`, graceful skipping

## Run it

```bash
T=//128_target_compatible_with

# The wildcard SKIPS incompatible targets instead of failing:
bazel test $T/...

# Naming an incompatible target explicitly is an ERROR:
bazel build $T:never_builds
```

On Linux, `windows_only_test` and `never_builds` are reported as skipped.

## The two behaviors

| How you ask | Incompatible target |
|-------------|---------------------|
| `//...` or `:all` wildcard | **Skipped**, build succeeds |
| Named explicitly | **Error**, with an explanation |

That asymmetry is the whole design. CI can run `bazel test //...` on every
platform and get exactly the tests that make sense there, while a developer who
explicitly asks for an impossible target still gets told why.

## The idioms

```python
# Only on Linux
target_compatible_with = ["@platforms//os:linux"]

# Linux AND x86_64 (constraints are ANDed)
target_compatible_with = ["@platforms//os:linux", "@platforms//cpu:x86_64"]

# Never buildable anywhere
target_compatible_with = ["@platforms//:incompatible"]

# Conditionally incompatible - the common real-world form
target_compatible_with = select({
    "@platforms//os:linux": [],                       # compatible
    "//conditions:default": ["@platforms//:incompatible"],
})
```

That last pattern reads oddly but is idiomatic: an empty list means "no extra
constraints", and `@platforms//:incompatible` is a constraint no platform ever
satisfies.

## Compare with the alternatives

| Approach | Problem |
|----------|---------|
| `tags = ["manual"]` | Excluded *everywhere*, including where it works |
| A `select()` on `srcs` | Still builds; just builds something different |
| Separate CI target lists | Drifts from reality immediately |
| `target_compatible_with` | Declared once, correct on every platform |

## Seeing why something was skipped

```bash
bazel test //... --show_result=100
bazel build //x:y   # name it explicitly - the error states the constraint
```

## Key takeaway

`target_compatible_with` lets one `bazel test //...` be correct on every
platform. It is the right answer to "this test only works on Linux".
