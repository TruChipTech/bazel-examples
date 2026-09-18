# 119 - OutputGroupInfo

**Concepts:** `OutputGroupInfo`, optional outputs, `output_group`

## Run it

```bash
O=//119_output_groups

# Default: only the primary artifact is built
bazel build $O:service
ls bazel-bin/119_output_groups/

# Request an extra group:
bazel build $O:service --output_groups=debug_symbols
bazel build $O:service --output_groups=documentation,coverage_data
bazel build $O:service --output_groups=everything

# Pull a group out with a filegroup:
bazel build $O:doc_index
cat bazel-bin/119_output_groups/index.md
```

## The point: outputs you do not always want

Debug symbols, documentation, coverage data, IDE metadata, generated headers -
all useful, none needed on every build. Putting them in `DefaultInfo.files`
would force everyone to build them every time.

`OutputGroupInfo` makes them **lazy**: declared in the graph, built only on
request.

```python
return [
    DefaultInfo(files = depset([binary])),           # always
    OutputGroupInfo(debug_symbols = depset([debug])) # on request
]
```

## Consuming from the command line

```bash
bazel build //pkg:target --output_groups=debug_symbols
bazel build //pkg:target --output_groups=+debug_symbols   # ADD to the defaults
bazel build //pkg:target --output_groups=-_hidden_top_level_INTERNAL_
```

A leading `+` keeps the default outputs as well.

## Consuming from a rule

```python
filegroup(
    name = "all_docs",
    srcs = [":service", ":worker"],
    output_group = "documentation",
)
```

`filegroup` understands `output_group`, which is the simplest way to turn a
group into a normal dependency. A custom rule reads it directly:

```python
docs = ctx.attr.dep[OutputGroupInfo].documentation
```

## Where you have already seen this

```bash
bazel build //x:y --output_groups=compilation_outputs   # rules_cc
bazel build //x:y --output_groups=+validation           # validation actions
```

The `validation` output group is special: Bazel builds it automatically for
every requested target, which is how rule sets run lint or policy checks
without anyone asking.

## Key takeaway

Keep `DefaultInfo.files` minimal and put everything optional in an output
group. It costs nothing when unused.
