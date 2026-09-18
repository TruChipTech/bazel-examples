# 167 - layering_check: Strict Deps for C++

**Concepts:** `layering_check`, `parse_headers`, transitive includes

## Run it

```bash
bazel build //167_layering_check:app
```

Now uncomment `#include "lib_public.h"` in `app.cc` and build again. By default
it **still compiles** - the header is reachable through `mid`'s transitive
dependencies.

That is the problem. `app` now depends on `lib_public` without declaring it, so
removing `mid`'s dependency on `lib_public` breaks `app` for no visible reason.

## Enabling the check

```bash
bazel build //167_layering_check:app --features=layering_check
```

```
error: module //167_layering_check:mid does not depend on a module
exporting 'lib_public.h'
```

Enable it repo-wide:

```
# .bazelrc
build --features=layering_check
```

or per package:

```python
package(features = ["layering_check"])
```

## Requirements

`layering_check` needs a toolchain that supports **Clang modules** - it is
implemented with `-fmodule-map-file` and module maps. It works with Clang; GCC
does not support it, which is why it is not on in this repo (the local
toolchain is GCC 11).

If you are on Clang, turning it on is one of the highest-value flags available.

## The equivalent in other languages

| Language | Mechanism | Default |
|----------|-----------|---------|
| Java | Strict deps | **On** (sample 076) |
| C++ | `layering_check` | Off (needs Clang) |
| Python | None enforced | - |
| Go | The compiler enforces it | On |

Java's strict deps is why sample 076 forced an explicit
`java_proto_library` dependency. C++ has the same problem and an opt-in
solution.

## The related feature: `parse_headers`

```
build --features=parse_headers
```

Compiles each header **on its own** to verify it is self-contained - that it
includes everything it uses. Without it, a header that silently depends on
being included after another one works until someone reorders includes.

## Why this matters at scale

Undeclared transitive dependencies make a build graph a lie. `bazel query
rdeps` under-reports, refactors break distant code, and "remove this unused
dependency" becomes a research project. Strictness keeps the declared graph
equal to the real graph.

## Key takeaway

`--features=layering_check` gives C++ the strict-deps guarantee Java has by
default. Turn it on if your toolchain is Clang.
