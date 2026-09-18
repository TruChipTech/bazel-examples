# 021 - srcs vs hdrs vs deps

**Concepts:** public interface, private headers, encapsulation

## Run it

```bash
bazel run //021_srcs_hdrs_deps:user
```

## The three attributes

| Attribute | Contains | Visible to consumers? |
|-----------|----------|-----------------------|
| `srcs` | Implementation files + **private** headers | No |
| `hdrs` | The public interface | Yes |
| `deps` | Other targets this one needs | Their `hdrs`, transitively |

## Prove the encapsulation

Uncomment the `#include "private_impl.h"` line in `user.cc` and build:

```
ERROR: ... this rule is missing dependency declarations for the following
files included by 'user.cc': 'private_impl.h'
```

Even though `private_impl.h` is one directory away and `user` already depends
on the library that owns it, Bazel refuses. A header in `srcs` is an
implementation detail, permanently.

## Why put a header in `srcs` at all?

So it is still a declared input - Bazel knows `impl.cc` depends on it and will
rebuild when it changes - while staying out of the public API.

## Key takeaway

`hdrs` is your published contract. Anything you might want to change without
breaking callers belongs in `srcs`.
