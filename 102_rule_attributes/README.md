# 102 - Rule Attributes

**Concepts:** attribute declaration, `ctx.attr` vs `ctx.file(s)`

## Run it

```bash
bazel build //102_rule_attributes:all
cat bazel-bin/102_rule_attributes/full_report.txt
cat bazel-bin/102_rule_attributes/minimal_report.txt
```

## Reading attribute values

The access path depends on the attribute type, and this is the part that trips
people up:

| Declared as | Read with | You get |
|-------------|-----------|---------|
| `attr.string()` | `ctx.attr.name` | a string |
| `attr.int()` | `ctx.attr.name` | an int |
| `attr.string_list()` | `ctx.attr.name` | a list of strings |
| `attr.label()` | `ctx.attr.name` | a **Target** object |
| `attr.label(allow_single_file=True)` | `ctx.file.name` | a **File** |
| `attr.label_list()` | `ctx.attr.name` | a list of Targets |
| `attr.label_list(allow_files=True)` | `ctx.files.name` | a flat list of Files |

Remember: `ctx.attr` for values and Targets, `ctx.file`/`ctx.files` for Files.

## Label attributes create edges

```python
"data": attr.label_list(allow_files = True),
```

This is not just a typed value. Every label listed becomes a **dependency** of
this target: Bazel builds those targets first, and they appear in
`bazel query "deps(...)"`. That is how a rule gets its inputs.

## Naming conventions

| Name | Conventional meaning |
|------|---------------------|
| `srcs` | Files consumed at build time |
| `deps` | Other targets, usually providing a provider |
| `data` | Runtime files (runfiles) |
| `hdrs` | Public headers |
| `outs` | Declared outputs |

Following these makes your rule feel native. A rule with a `sources` attribute
instead of `srcs` will confuse everyone who uses it.

## Documenting

```python
"title": attr.string(mandatory = True, doc = "The report heading."),
```

`doc` strings feed Stardoc, which generates reference documentation from the
rule definition - the same way the official rule docs are produced.

## Key takeaway

Attributes are the rule's public API. Choose the types carefully; label
attributes are dependency edges, not just strings.
