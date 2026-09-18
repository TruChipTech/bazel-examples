# 094 - Query Output Formats and genquery

**Concepts:** `--output`, Graphviz, `genquery`

## Run it

```bash
bazel build //094_query_output:trunk_deps
cat bazel-bin/094_query_output/trunk_deps
```

## The output formats

```bash
Q=//094_query_output

bazel query "deps($Q:trunk)"                          # label (default)
bazel query "deps($Q:trunk)" --output=label_kind      # "py_library rule //x:y"
bazel query "deps($Q:trunk)" --output=build           # reconstructed BUILD syntax
bazel query "deps($Q:trunk)" --output=location        # file:line of each target
bazel query "deps($Q:trunk)" --output=package         # just package names
bazel query "deps($Q:trunk)" --output=graph           # Graphviz DOT
bazel query "deps($Q:trunk)" --output=xml             # XML, for tooling
bazel query "deps($Q:trunk)" --output=proto           # binary proto
bazel query "deps($Q:trunk)" --output=streamed_jsonproto  # JSON lines
```

## Which to use when

| Goal | Format |
|------|--------|
| Read it yourself | `label` or `label_kind` |
| "What did that macro generate?" | `build` |
| "Where is this target defined?" | `location` |
| Draw a picture | `graph` |
| Feed a script | `streamed_jsonproto` |

## Drawing the graph

```bash
bazel query "deps(//093_query_operators:server)" \
  --output=graph --noimplicit_deps > /tmp/graph.dot
dot -Tpng /tmp/graph.dot -o /tmp/graph.png
```

`--noimplicit_deps` is essential - without it the toolchain nodes make the
picture unreadable.

## `genquery`: a query result as a build artifact

```python
genquery(
    name = "trunk_deps",
    expression = "deps(//pkg:trunk)",
    scope = [":trunk"],
)
```

The output file can then be consumed by other rules. Real uses:

- Generating a dependency report or SBOM as part of the build
- Producing a license manifest from the dependency closure
- A test that asserts a forbidden dependency does not exist

`scope` is mandatory and must cover everything the expression touches - it is
what makes the query hermetic and cacheable.

## Guarding architecture with genquery

```python
genquery(
    name = "frontend_deps",
    expression = "deps(//frontend:app)",
    scope = ["//frontend:app"],
)

# then a test asserting //backend/internal does not appear in that output
```

This turns a layering rule into a build failure - a lighter-weight alternative
to visibility when the rule is about whole subsystems.

## Key takeaway

`--output` formats make query scriptable; `genquery` makes query results part
of the build graph.
