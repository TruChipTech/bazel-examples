# 121 - Implicit Dependencies

**Concepts:** private attributes, `_` prefix, hidden tools

## Run it

```bash
bazel build //121_implicit_deps:pretty
cat bazel-bin/121_implicit_deps/pretty.txt

# The tool IS a real dependency, even though the BUILD file never says so:
bazel query 'deps(//121_implicit_deps:pretty)' --noimplicit_deps
bazel query 'deps(//121_implicit_deps:pretty)'
```

The second query shows `:formatter`; the first hides it. That is exactly what
`--noimplicit_deps` means.

## The convention

```python
"_formatter": attr.label(
    default = Label("//pkg:formatter"),
    cfg = "exec",
    executable = True,
),
```

A leading underscore makes the attribute **private**: callers cannot set it,
and it must have a default. Everything else about it is normal - it is a real
dependency edge, built before the action runs, and tracked for invalidation.

## Why this matters

Every compiler, linter, code generator and wrapper script a rule uses is an
implicit dependency. The user of `cc_library` does not pass in a C++ compiler;
`cc_library` knows where to find it.

Because it is a tracked edge:

- Changing the tool's source rebuilds everything that uses it
- The tool is built automatically, in the right configuration
- `bazel query` can answer "what depends on this tool?"

None of that is true of a script invoked by absolute path from a genrule.

## `Label()` in the default

```python
default = Label("//pkg:formatter")    # correct
default = "//pkg:formatter"           # works, but resolves in the CALLER's repo
```

Wrapping in `Label()` resolves the string **where the .bzl file lives**, which
is what you want when your rule is used from another repository. A bare string
can resolve to a nonexistent target in someone else's workspace.

This is a real bug that only appears once your rule set has external users.

## Making it overridable

Drop the underscore to let callers substitute a different tool:

```python
"formatter": attr.label(default = Label("//pkg:formatter"), cfg = "exec", executable = True),
```

For build-wide substitution, a `label_flag` (sample 060) is usually better.

## Key takeaway

Private `_`-prefixed label attributes are how rules carry their own tooling.
Always wrap the default in `Label()`.
