# 003 - Libraries and Dependencies

**Concepts:** `cc_library`, `deps`, `hdrs` vs `srcs`

## Run it

```bash
bazel run //003_cc_library_deps:main
```

## srcs vs hdrs

- `srcs` are compiled *into* this target. Consumers cannot include them.
- `hdrs` form the target's public interface. Only headers listed in `hdrs` may
  be `#include`d by a target that depends on this one.

This is **strict header inclusion**, and it is a feature. Delete
`deps = [":math_utils"]` and rebuild:

```
main.cc:3:10: fatal error: math_utils.h: No such file or directory
```

The file exists on disk right next to `main.cc`, but Bazel compiles inside a
sandbox containing only the files you declared. Undeclared dependencies fail
loudly instead of working by accident and breaking on a different machine.

## The `:` prefix

`:math_utils` is a shorthand for "target in this same package". The full label
is `//003_cc_library_deps:math_utils`.

## Key takeaway

Dependencies are explicit. If a target needs a header, it must declare a `deps`
edge to whichever target owns that header.
