# 080 - The C++ Runfiles Library

**Concepts:** `Rlocation`, robust data access

## Run it

```bash
bazel run //080_cc_runfiles:reader

# Also works when executed directly, unlike a hard-coded relative path:
bazel build //080_cc_runfiles:reader
./bazel-bin/080_cc_runfiles/reader
```

## Why not just open the relative path?

Earlier samples did exactly that:

```cpp
std::ifstream in("009_sh_test/config.ini");
```

It works under `bazel run` and `bazel test`, because the working directory is
the runfiles root. It breaks when:

- The binary is run directly from `bazel-bin`
- The binary is invoked as a `tool` by another rule
- The platform uses a runfiles **manifest** instead of a symlink tree (Windows)
- The data comes from an external repository

The runfiles library handles all of these.

## The API

```cpp
#include "tools/cpp/runfiles/runfiles.h"
using bazel::tools::cpp::runfiles::Runfiles;

std::string error;
std::unique_ptr<Runfiles> rf(Runfiles::Create(argv[0], &error));
std::string path = rf->Rlocation("_main/path/to/file.txt");
```

For a **test**, use `Runfiles::CreateForTest(&error)` instead - it reads the
test environment rather than `argv[0]`.

## The repository prefix

```
_main/080_cc_runfiles/message.txt
^^^^^
```

Under bzlmod the main repository's runfiles directory is `_main`. A file from
an external module uses that module's canonical repo name instead. This is the
detail people get wrong most often; if `Rlocation` returns an empty string,
print the key you passed and check the prefix.

## The dependency

```python
deps = ["@bazel_tools//tools/cpp/runfiles"],
```

Equivalents: `@rules_python//python/runfiles` (sample 081),
`@bazel_tools//tools/java/runfiles` for Java, `@rules_go//go/runfiles` for Go.

## Key takeaway

Any program that reads `data` files and might be run outside `bazel run`
should use the runfiles library. It is a few lines and removes a whole class of
"works on my machine".
