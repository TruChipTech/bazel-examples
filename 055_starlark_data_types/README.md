# 055 - Starlark Data Types

**Concepts:** `dict`, `struct`, immutability, `depset` preview

## Run it

```bash
bazel build //055_starlark_data_types:all
cat bazel-bin/055_starlark_data_types/billing_manifest.txt
cat bazel-bin/055_starlark_data_types/linux_flags.txt
```

## The types

| Type | Literal | Mutable? |
|------|---------|----------|
| `string` | `"x"` | No |
| `int` | `42` | No |
| `bool` | `True` | No |
| `list` | `[1, 2]` | Yes, until frozen |
| `dict` | `{"a": 1}` | Yes, until frozen |
| `tuple` | `(1, 2)` | No |
| `struct` | `struct(a = 1)` | **No** |
| `depset` | `depset([...])` | No (sample 116) |

## `struct` is the record type

```python
s = struct(name = "auth", port = 9001)
s.name        # "auth"
s.port = 1    # ERROR - structs are immutable
```

Structs are how you return several values from a helper, and how providers
(sample 114) carry data between rules. Build a new one instead of mutating.

## Everything freezes

When a `.bzl` file finishes loading, all of its top-level values become
**immutable**, permanently. This is why:

```python
COMMON_FLAGS = ["-Wall"]

def add_flag(f):
    COMMON_FLAGS.append(f)   # ERROR at call time: trying to mutate a frozen value
```

Build a new list instead: `COMMON_FLAGS + [f]`.

Freezing is what makes it safe for Bazel to load a `.bzl` file once and share
it across every package that loads it, in parallel.

## Preview: `depset`

For large transitive sets, `list` concatenation is O(n²). `depset` is the
optimized structure Bazel uses for dependency closures - covered in sample 116.

## Key takeaway

Prefer `struct` for grouped data, build new values instead of mutating, and
remember that everything freezes at the end of loading.
