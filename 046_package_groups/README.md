# 046 - package_group: Managing Visibility at Scale

**Concepts:** `package_group`, `includes`, allowlists

## Run it

```bash
bazel run //046_package_groups/allowed:use
```

## Break it

Add this to `other/BUILD.bazel`:

```python
py_binary(
    name = "sneaky",
    srcs = ["use.py"],
    deps = ["//046_package_groups/core:engine"],
)
```

It fails: `other` is not in `:internal_users`.

## Why not just list packages in `visibility`?

Because the list is duplicated on every target that needs it. With 30 targets
and 12 allowed consumers, adding a consumer is a 30-file change. A
`package_group` makes it one line.

## Group syntax

```python
package_group(
    name = "clients",
    packages = [
        "//services/api",            # exactly this package
        "//services/worker/...",     # this package and everything below
        "//...",                     # the entire repo
    ],
    includes = [":other_group"],     # groups compose
)
```

## The allowlist pattern

This is how large repos gate access to sensitive or deprecated APIs:

```python
package_group(
    name = "legacy_auth_users",
    packages = ["//services/billing", "//services/reports"],
)
```

New code cannot use the legacy API without an explicit, reviewable edit to the
allowlist. The list only shrinks as teams migrate.

## Key takeaway

`package_group` turns visibility from per-target boilerplate into a named,
reviewable policy.
