# 052 - Symbolic Macros

**Concepts:** `macro()`, attribute schemas, naming rules

## Run it

```bash
bazel run //052_symbolic_macros:api
bazel query --output=build //052_symbolic_macros:api
```

## What `macro()` adds over a plain function

```python
service = macro(
    implementation = _service_impl,
    attrs = {
        "srcs": attr.label_list(mandatory = True),
        "port": attr.int(default = 8080),
    },
)
```

1. **Declared attributes.** Passing an unknown attribute or the wrong type is
   an error with a good message, instead of a `TypeError` deep inside the
   function.
2. **Naming discipline.** Every target a symbolic macro creates must be named
   `name` or `name + "_suffix"`. Tooling can now map any target back to the
   macro call that produced it.
3. **Private by default.** Internal targets are not visible outside unless you
   explicitly pass `visibility`. Legacy macros leaked every target.
4. **Lazy evaluation.** Bazel can skip expanding a macro whose targets nobody
   requested, which speeds up loading in huge packages.

## `configurable = False`

By default a symbolic macro's attributes accept `select()`, which means the
implementation receives an opaque object rather than a value. Mark an attribute
`configurable = False` when the implementation needs the actual value at
loading time - as `port` does here, since it is formatted into a string.

## When to use which

| Use | When |
|-----|------|
| Symbolic macro | New code. Always, unless you need something it forbids. |
| Legacy macro | Existing code, or genuinely dynamic target names |
| Rule | You need to create **actions**, not just targets (sample 101) |

## Key takeaway

Symbolic macros give macros a schema and an encapsulation boundary. They are
the default choice in Bazel 8+.

## Label visibility: the restriction that bites first

A symbolic macro may only use labels that were **passed to it as attributes**.
This fails:

```python
def _impl(name, visibility, **kwargs):
    py_binary(name = name, srcs = [name + "_main.py"])   # ERROR
```

```
ERROR: no such target ':api_main.py' ... however, a source file of this
name exists
```

A legacy macro can name any sibling file it likes. A symbolic macro cannot,
because Bazel wants the macro's inputs to be visible in the call site. The fix
is an explicit attribute:

```python
attrs = {"main": attr.label(allow_single_file = [".py"], mandatory = True)}
```

This is the most common surprise when migrating a legacy macro, and it is
working as intended: the dependency is now declared where a reader can see it.

Note the second half of the fix: the attribute is also marked
`configurable = False`. Without it the macro receives a `select()` wrapper
rather than the label itself, and passing that to `py_binary(srcs = ...)`
fails with *"expected value of type 'string' ... but got select"*.

Rule of thumb: if the implementation needs to **look at** a value (format it,
index it, pass it where a plain string is required), mark it
`configurable = False`.
