# 081 - The Python Runfiles Library

**Concepts:** `python.runfiles`, `Rlocation`, tests vs binaries

## Run it

```bash
bazel run  //081_py_runfiles:render -- Alice
bazel test //081_py_runfiles:render_test
```

## The API

```python
from python.runfiles import runfiles

r = runfiles.Create()
path = r.Rlocation("_main/path/from/workspace/root/file.txt")
```

`Create()` works for both binaries and tests - it inspects `RUNFILES_DIR`,
`RUNFILES_MANIFEST_FILE` and `argv[0]` to find the tree.

It returns `None` when the program is not running under Bazel at all, so check
for that if the script is also meant to run standalone.

## The dependency

```python
deps = ["@rules_python//python/runfiles"],
```

## Debugging `Rlocation` returning `None`

Almost always the key prefix. Print what is actually there:

```python
import os
print(os.environ.get("RUNFILES_DIR"))
for root, dirs, files in os.walk(os.environ["RUNFILES_DIR"]):
    print(root, files)
```

Under bzlmod:

| File from | Prefix |
|-----------|--------|
| The main repo | `_main/` |
| An external module `foo` | the canonical repo name, e.g. `foo+/` |

Rather than hard-coding a prefix for external files, have the rule pass the
path in with `$(rootpath //external:file)` (sample 037).

## Why a test needs this too

A test's working directory is the runfiles root today, but that is an
implementation detail. Using the library means the test keeps working if it is
later wrapped in a different runner, run remotely, or run on Windows where a
manifest replaces the symlink tree.

## Key takeaway

`runfiles.Create()` + `Rlocation()` is three lines and makes data access
portable. Use it in anything beyond a throwaway script.
