# 145 - The Args API

**Concepts:** `ctx.actions.args()`, lazy expansion, `map_each`

## Run it

```bash
bazel build //145_args_api:demo
cat bazel-bin/145_args_api/demo.txt
```

## Why not a plain list?

```python
arguments = ["--src", f1.path, "--src", f2.path, ...]   # a Python list
arguments = [args]                                       # an Args object
```

An `Args` object is **lazy**. The command line is materialized only if the
action actually runs, and the expansion happens in Bazel's Java layer rather
than in Starlark. For an action with ten thousand inputs, that difference is
the whole analysis budget.

`Args` also handles parameter files automatically (sample 146), which a plain
list cannot.

## The API

```python
args = ctx.actions.args()

args.add(value)                              # one value
args.add("--flag", value)                    # flag + value
args.add_all(values)                         # a list or depset
args.add_all("--flag", values)               # flag ONCE, then all values
args.add_all(values, before_each = "--flag") # flag before EACH value
args.add_joined("--flag", values, join_with = ",")   # one joined argument
```

Note the difference between the second and third forms - it catches people out:

```
add_all("--src", [a, b])          ->  --src a b
add_all([a, b], before_each="--src") ->  --src a --src b
```

## The modifiers

| Parameter | Effect |
|-----------|--------|
| `format_each = "--in=%s"` | Format every element |
| `map_each = fn` | Transform every element |
| `uniquify = True` | Drop duplicates |
| `omit_if_empty = True` | Emit nothing if the list is empty |
| `expand_directories = True` | Expand tree artifacts to their files |
| `before_each = "-I"` | Insert a token before each element |

## `map_each` runs at execution time

```python
def _basename_only(f):
    return f.basename

args.add_all(ctx.files.srcs, map_each = _basename_only)
```

The function is called when the command line is built - which is when the
action runs, not during analysis. So an action that is cached never pays for
it. This is why `map_each` is preferred over a Starlark list comprehension.

The function must be a **top-level** function (not a closure) and must return a
string, a list of strings, or `None`.

## Depsets go in directly

```python
args.add_all(my_depset)          # correct
args.add_all(my_depset.to_list()) # flattens in Starlark - avoid
```

## Key takeaway

Use `Args` for every non-trivial command line. It is lazy, it handles depsets
and tree artifacts, and it enables param files for free.
