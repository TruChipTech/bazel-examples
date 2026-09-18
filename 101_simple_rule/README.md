# 101 - Your First Custom Rule

**Concepts:** `rule()`, implementation functions, analysis phase

## Run it

```bash
bazel build //101_simple_rule:all
cat bazel-bin/101_simple_rule/bazel_greeting.txt
```

## The anatomy

```python
def _greeting_impl(ctx):          # 1. implementation function
    out = ctx.actions.declare_file(...)   # 2. declare outputs
    ctx.actions.write(...)                # 3. register actions
    return [DefaultInfo(files = depset([out]))]   # 4. return providers

greeting = rule(                  # 5. bind it together
    implementation = _greeting_impl,
    attrs = {"who": attr.string(default = "world")},
)
```

## Rule vs macro - the real difference

| | Macro | Rule |
|---|-------|------|
| Phase | Loading | **Analysis** |
| Produces | Other targets | **Actions** |
| Can create files | No | **Yes** |
| Sees configuration | No | **Yes** (`select()` resolved) |
| Bazel models it | No | **Yes** - it is a node in the graph |

If you need to *generate a file*, you need a rule (or a genrule, which is a
generic one). If you only need to *declare targets*, a macro is simpler and
cheaper.

## The implementation function does no work

This is the idea that takes longest to internalize. `_greeting_impl` runs
during analysis and only **describes** an action. Bazel builds a graph of those
descriptions, then executes the subset needed for the requested targets - in
parallel, remotely, or not at all if the result is cached.

So the implementation must never:

- Read or write files directly (there is no file I/O in Starlark)
- Depend on wall-clock time, the environment, or randomness
- Assume it runs once per build - it runs once per *configuration*

## `ctx` is everything

| Field | Gives you |
|-------|-----------|
| `ctx.attr.<name>` | Attribute values |
| `ctx.file` / `ctx.files` | Attribute values as `File` objects |
| `ctx.actions` | The action factory |
| `ctx.label` | This target's label |
| `ctx.outputs` | Predeclared outputs |
| `ctx.executable` | Executables from label attributes |
| `ctx.toolchains` | Resolved toolchains |

## Key takeaway

A rule implementation is a pure function from attributes to a description of
actions. Nothing executes until Bazel decides it must.
