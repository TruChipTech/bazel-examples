# 039 - Header-Only Libraries

**Concepts:** `hdrs` without `srcs`, interface targets

## Run it

```bash
bazel run //039_header_only:use_vec
```

## Why declare a target with no sources?

Because a header-only library still has:

- **An include path** that consumers need.
- **Dependencies** of its own, which must propagate.
- **A visibility boundary**, so not everyone can include it.
- **A name in the graph**, so `bazel query rdeps` can find its users.

Skipping the target and letting consumers list `vec.h` in their own `srcs`
would mean every consumer re-declares the same information, and Bazel's strict
header checks would fail for anyone who forgot.

## Verify nothing was compiled

```bash
bazel build //039_header_only:vec
# No .a or .o is produced for this target.
```

## `textual_hdrs` for the awkward cases

Some headers are not self-contained - they are meant to be `#include`d in the
middle of another file (`.inc` files, X-macro lists). Strict header parsing
would reject them. Declare those in `textual_hdrs` instead of `hdrs`:

```python
cc_library(
    name = "tables",
    textual_hdrs = ["opcodes.inc"],
)
```

## Key takeaway

A target is a node in the dependency graph, not necessarily a compilation step.
Header-only libraries carry metadata, and that is reason enough to declare them.
