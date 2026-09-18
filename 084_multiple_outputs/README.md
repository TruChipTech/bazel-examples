# 084 - Multiple Outputs From One Action

**Concepts:** multiple `outs`, `$(location)`, output selection

## Run it

```bash
bazel build //084_multiple_outputs:split_schema
cat bazel-bin/084_multiple_outputs/summary.txt
cat bazel-bin/084_multiple_outputs/user_schema.txt

# Depending on just one output still runs the single action:
bazel build //084_multiple_outputs:user_only
```

## `$@` stops working

With one output, `$@` is that file. With several it is ambiguous, so you must
name each one:

```python
cmd = "... > $(location user_schema.txt)"
```

Forgetting this yields a confusing shell error, because `$@` expands to the
whole output list.

## Every declared output must be created

Declare three, write two, and the action fails:

```
ERROR: declared output 'summary.txt' was not created by genrule
```

The reverse is also true - writing an undeclared file has no effect, since it
is discarded with the sandbox.

## Referring to one output

```python
srcs = ["user_schema.txt"]        # just this file
srcs = [":split_schema"]          # ALL outputs of the rule
```

An output file is addressable by its own label. This is what lets a downstream
target depend on a narrow slice without pulling in everything.

## Rules can be more precise than genrules

A genrule's outputs are a flat list. A real rule can group them with
`OutputGroupInfo` (sample 119), so consumers can ask for "just the headers" or
"just the debug symbols":

```bash
bazel build //pkg:target --output_groups=headers
```

## Key takeaway

Multiple outputs are fine and often desirable - one action producing five files
is cheaper than five actions. Just name each output explicitly in `cmd`.
