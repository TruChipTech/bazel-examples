# 022 - Controlling Include Paths

**Concepts:** `strip_include_prefix`, `include_prefix`, `includes`

## Run it

```bash
bazel run //022_include_paths:demo
```

## The problem

Bazel's default include path for a header is its **workspace-relative path**.
For a header at `022_include_paths/include/mylib/strings.h` that
means consumers would write:

```cpp
#include "022_include_paths/include/mylib/strings.h"
```

That is unusable, and it changes whenever you move the directory.

## The two attributes

- `strip_include_prefix = "include"` - drop that leading segment.
  Result: `#include "mylib/strings.h"`.
- `include_prefix = "acme"` - add a segment.
  Combined with the strip above: `#include "acme/mylib/strings.h"`.

Together they let the include path be a deliberate API decision that is
independent of where the files physically live.

## The legacy `includes` attribute

`includes = ["include"]` does something similar but adds a `-I` flag that
leaks into every transitive consumer, which causes header collisions at scale.
Prefer `strip_include_prefix`.

## Key takeaway

The include path is part of your public API. Set it explicitly so you can move
directories without a repo-wide sed.
