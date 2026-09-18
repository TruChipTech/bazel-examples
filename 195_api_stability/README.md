# 195 - Rule Set API Stability

**Concepts:** what is public, deprecation, versioning

## What counts as your public API

More than you think:

| Surface | Breaking it means |
|---------|-------------------|
| Rule names and load paths | Every `load()` breaks |
| Attribute names, types, defaults | Every call site breaks |
| Provider names and **fields** | Every consumer rule breaks |
| Predeclared output names | Every target depending on `:foo_deploy.jar` breaks |
| Toolchain type labels | Every registration breaks |
| Make variables from `TemplateVariableInfo` | Every `$(VAR)` breaks |
| Error message text | Anyone matching on it breaks (rare, but real) |

The one people forget is **provider fields**. Renaming `srcs` to
`transitive_srcs` in a provider is a breaking change for every rule that reads
it, and there is no deprecation mechanism for a field.

## Structure the API deliberately

```
rules/
  defs.bzl          # THE public entry point - re-exports only
  providers.bzl     # public providers
  internal/
    impl.bzl        # private; underscore-prefixed symbols
    utils.bzl
```

```python
# defs.bzl - the only file users should load
load("//rules/internal:impl.bzl", _my_rule = "my_rule")

my_rule = _my_rule
```

A single documented entry point means you can restructure everything behind it.
Users loading `//rules/internal:impl.bzl` directly are outside the contract -
and you can enforce that with visibility (sample 015).

## Deprecating

```python
my_old_rule = rule(
    implementation = _impl,
    doc = "DEPRECATED: use my_new_rule. Removed in 2.0.",
)
```

For targets, the `deprecation` attribute warns every consumer on every build:

```python
py_library(
    name = "old_client",
    deprecation = "Use //net:client_v2; removed after 2026-12-01.",
)
```

That warning is the cheapest migration tool available and is badly underused.

## Adding attributes safely

| Change | Safe? |
|--------|-------|
| Add an attribute **with a default** | Yes |
| Add a mandatory attribute | **No** - breaks every caller |
| Add a provider field | Yes |
| Remove or rename anything | **No** |
| Loosen validation | Yes |
| Tighten validation | **No** - existing callers may violate it |
| Change a default value | **No** - silent behavior change |

Changing a default is the sneaky one: nothing fails, behavior just differs.

## Version with semver and mean it

```python
module(name = "rules_mylang", version = "2.1.0")
```

- **Major**: any breaking change from the table above
- **Minor**: new rules, new optional attributes
- **Patch**: bug fixes with no interface change

Under MVS (sample 164), consumers only move when they ask to - so a major bump
is not disruptive, provided you actually bump it.

## Test your API

Analysis tests (sample 186) pin provider fields, attribute defaults and error
messages. Without them, a refactor breaks downstream users and you find out
from a bug report.

## Key takeaway

Providers and attribute defaults are API. Route everything through one public
`defs.bzl`, use `deprecation` warnings, and pin the interface with tests.
