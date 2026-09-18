# 131 - Aspect Propagation

**Concepts:** `attr_aspects`, aspect attributes, traversal control

## Run it

```bash
P=//131_aspect_propagation

bazel build $P:app \
  --aspects=//131_aspect_propagation:trace.bzl%trace_aspect \
  --output_groups=trace

cat bazel-bin/131_aspect_propagation/app.trace
```

The trace lists `app`, `core`, `util` **and** `assets` - because
`attr_aspects` includes both `deps` and `data`.

## Choosing what to follow

```python
attr_aspects = ["deps"]                  # dependency graph only
attr_aspects = ["deps", "data", "srcs"]  # several edges
attr_aspects = ["*"]                     # every label attribute
```

`["*"]` is tempting and usually wrong: it drags in toolchains, implicit
dependencies and the entire compiler, making the aspect enormously expensive.
Name the attributes you actually care about.

## Aspects can have their own attributes

```python
trace_aspect = aspect(
    implementation = _impl,
    attr_aspects = ["deps"],
    attrs = {
        "_follow": attr.string_list(default = ["deps", "data"]),
        "_tool": attr.label(default = Label("//x:tool"), cfg = "exec", executable = True),
    },
)
```

Aspect attributes must be **private** (leading underscore) with defaults, or
have `values` specified - because a command-line aspect has no BUILD file in
which to set them. A rule that applies an aspect can pass parameters explicitly
(sample 132).

The `_tool` pattern is important: it is how a linting aspect carries its linter.

## `type(dep) == "Target"`

An attribute's value can be a single Target, a list, a string, or a dict.
When iterating generically, check types before treating a value as a
dependency - otherwise the aspect crashes on the first rule with an unexpected
attribute shape.

## Aspects on aspects

```python
my_aspect = aspect(..., requires = [other_aspect])
```

An aspect can require another to have run first, and read its providers. This
is how layered tooling composes - a codegen aspect feeding a compile aspect.

## Cost

An aspect runs once per (target, aspect) pair in the traversed graph. A broad
`attr_aspects` over a large repo means analyzing a lot. Measure with:

```bash
bazel build //... --aspects=... --profile=/tmp/prof.gz
bazel analyze-profile /tmp/prof.gz
```

## Key takeaway

`attr_aspects` is the traversal specification. Keep it narrow, give aspects
private attributes with defaults, and type-check when iterating generically.
