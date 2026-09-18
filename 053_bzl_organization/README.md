# 053 - Organizing .bzl Files

**Concepts:** `load()`, `bzl_library`, public vs private symbols

## Build it

```bash
bazel build //053_bzl_organization:widget
```

## The `load()` forms

```python
load(":local.bzl", "symbol")                       # same package
load("//path/to/pkg:defs.bzl", "symbol")           # another package
load("@rules_cc//cc:defs.bzl", "cc_library")       # external module
load(":defs.bzl", renamed = "original_name")       # rename on import
load(":defs.bzl", "a", "b", "c")                   # several at once
```

`load()` statements must be at the **top level** of a file - never inside a
function or an `if`.

## Underscore means private

```python
PUBLIC_THING = 1     # other files may load this
_private_thing = 2   # loading this from another file is an error
```

This is enforced, not a convention. It is how a `.bzl` file keeps an
implementation detail out of its API.

## Layering

```
constants.bzl   values only, no loads of your own rules
    ^
rules.bzl       macros and rules built on the constants
    ^
BUILD.bazel     the call sites
```

Keeping constants in their own file prevents cycles - `.bzl` files may not
have circular loads.

## `bzl_library`

It declares a set of `.bzl` files plus their dependencies as a target. It does
not affect `load()` - `load()` works with or without it. You need it for
Stardoc documentation generation and for Starlark unit tests (sample 188).

## Where to put them

The common convention is a top-level `build_defs/` or `bazel/` directory. Some
repos put `defs.bzl` next to the code it serves. Either works; consistency is
what matters.

## Key takeaway

Treat `.bzl` files like any other library code: layered, with a deliberate
public surface marked by the absence of a leading underscore.
