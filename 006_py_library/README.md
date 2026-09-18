# 006 - Python Libraries

**Concepts:** `py_library`, `imports`, transitive deps

## Run it

```bash
bazel run //006_py_library:app -- Bazel Builds Fast
```

## The `imports` attribute

Python resolves imports through `sys.path`. By default Bazel puts the
*workspace root* on the path, so the honest import would be:

```python
from 006_py_library.textlib import slugify   # not even valid syntax
```

`imports = ["."]` adds this package's own directory to the path instead,
letting consumers write `from textlib import slugify`. The attribute is applied
to anything that depends on the library, not just to the library itself.

## Transitivity

If `textlib` later gains `deps = [":formatting"]`, `app` gets `formatting`
automatically. You declare *direct* dependencies; Bazel computes the closure.

## Key takeaway

A library target is a unit of reuse plus a unit of caching. Change `app.py` and
only `app` rebuilds - `textlib` stays cached.
