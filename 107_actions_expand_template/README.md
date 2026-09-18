# 107 - ctx.actions.expand_template

**Concepts:** templating in rules, computed substitutions

## Run it

```bash
bazel run //107_actions_expand_template:auth
cat bazel-bin/107_actions_expand_template/auth_service.py
```

## Why a rule rather than skylib's `expand_template`

Sample 083 used the skylib **rule**, whose substitutions are written literally
in the BUILD file. This sample uses the **action**, whose substitutions are
computed in Starlark:

```python
endpoints_literal = "[%s]" % ", ".join(['"%s"' % e for e in ctx.attr.endpoints])
```

The value comes from an attribute, is transformed into a Python list literal,
and is substituted in. A BUILD-file-only approach cannot do that.

Other things only the action form can do:

- Derive values from `ctx.attr.deps` (their labels, files, or providers)
- React to the configuration (`ctx.var`, a `select()`ed attribute)
- Compute a value from the toolchain

## Code generation is the classic use

```python
ctx.actions.expand_template(
    template = ctx.file._runner_template,
    output = runner_script,
    substitutions = {
        "%{BINARY}": binary.short_path,
        "%{ARGS}": " ".join(ctx.attr.args),
    },
    is_executable = True,
)
```

Nearly every rule set generates a launcher or wrapper script this way -
`py_binary`, `java_binary` and `sh_test` all do.

## Substitution rules

- Literal string replacement, **not** regex
- Applied in unspecified order, so patterns must not overlap
- Every occurrence is replaced

Choose delimiters that cannot occur naturally: `%{NAME}`, `@NAME@`,
`{{NAME}}`. Bare `NAME` will corrupt unrelated text.

## `is_executable`

Set it when generating a script. It is the difference between a runnable
launcher and a "permission denied" at the worst moment.

## Key takeaway

Use the skylib rule for static substitutions in BUILD files; use
`ctx.actions.expand_template` when the values must be computed during analysis.

## Gotcha: declared files are not addressable by name

```python
py_binary(srcs = [":auth_service.py"])   # ERROR - no such target
py_binary(srcs = [":auth_service"])      # correct - depend on the RULE
```

A file created with `ctx.actions.declare_file` exists in the action graph but
has **no label of its own**. Only *predeclared* outputs - those from an
`attr.output` attribute or the rule's `outputs` parameter - get individual
labels.

To consume a rule's generated files, depend on the rule target; its
`DefaultInfo.files` carries them. If callers genuinely need to reference one
output by name, declare it as an `attr.output`:

```python
attrs = {"out": attr.output()}
# then: ctx.outputs.out  instead of ctx.actions.declare_file(...)
```
