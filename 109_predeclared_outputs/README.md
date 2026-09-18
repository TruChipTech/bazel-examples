# 109 - Predeclared Outputs

**Concepts:** `attr.output`, the `outputs` dict, addressable files

## Run it

```bash
P=//109_predeclared_outputs

bazel build $P:split
cat bazel-bin/109_predeclared_outputs/first_three.txt

# The individual output has its own label:
bazel build $P:first_three.txt
bazel build $P:head_only

bazel build $P:quarterly_summary.txt
```

## Three ways a rule produces outputs

| Mechanism | Filename chosen by | Has its own label? |
|-----------|--------------------|--------------------|
| `ctx.actions.declare_file()` | The rule | **No** |
| `attr.output` | The **caller**, in the BUILD file | **Yes** |
| `outputs = {"k": "%{name}_x.txt"}` | The rule, from a template | **Yes** |

## When you need a label

```python
genrule(srcs = ["first_three.txt"], ...)     # works: predeclared
genrule(srcs = [":auth_service.py"], ...)    # fails: declare_file output
```

If consumers must depend on **one specific output** rather than all of them,
it has to be predeclared. Otherwise they depend on the rule target and get
everything in `DefaultInfo.files`.

## The `%{name}` template

```python
outputs = {"summary": "%{name}_summary.txt"}
```

`named_report(name = "quarterly")` therefore produces
`//pkg:quarterly_summary.txt`. This is how `java_binary` gives you
`<name>_deploy.jar` and `cc_binary` gives you `<name>.stripped` without you
declaring anything.

You can also substitute any string attribute: `%{some_attr}`.

## Prefer `declare_file` by default

Predeclared outputs are part of your rule's **public API**: once someone
depends on `//pkg:foo_summary.txt`, you cannot rename it. `declare_file` keeps
the output an implementation detail you can change freely.

Use predeclared outputs when the individual file genuinely is an interface -
a deploy jar, a stripped binary, a generated header consumers include.

## `OutputGroupInfo` is often the better answer

For "give me just the debug symbols", output groups (sample 119) are more
flexible than predeclared labels and do not freeze filenames.

## Key takeaway

`declare_file` for internal outputs; `attr.output` or the `outputs` dict when
the filename is part of the contract.
