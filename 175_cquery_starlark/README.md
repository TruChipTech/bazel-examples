# 175 - cquery with Starlark Output

**Concepts:** `--output=starlark`, programmatic build queries

## Run it

```bash
S=//175_cquery_starlark

# A one-line expression
bazel cquery $S:tool --output=starlark --starlark:expr='target.label'

# Output file paths
bazel cquery $S:tool --output=starlark \
  --starlark:expr='[f.path for f in target.files.to_list()]'

# A whole script
bazel cquery $S:tool --output=starlark \
  --starlark:file=175_cquery_starlark/providers.cquery
```

## What the script gets

```python
def format(target):
    target.label                    # the Label
    target.files                    # depset of output Files
    providers(target)               # dict of provider name -> provider
    return "..."                    # one string per target
```

`format(target)` is called once per configured target in the result set, and
whatever it returns is printed.

## Why this is better than parsing text output

The other `--output` formats give you text you must then parse. Starlark output
lets you extract **exactly** the fields you need, in the shape you need, from
the real configured target - including provider contents that no text format
exposes.

## Things people actually do with it

**Locate an output whose path depends on configuration:**
```bash
bazel cquery //cmd:server --platforms=//platforms:arm64 \
  --output=starlark --starlark:expr='target.files.to_list()[0].path'
```

**List every test target and its size:**
```bash
bazel cquery 'kind(".*_test", //...)' --output=starlark \
  --starlark:expr='target.label'
```

**Inspect a custom provider across the graph:**
```python
def format(target):
    p = providers(target)
    info = p.get("//my/pkg:defs.bzl%MyInfo")
    return "%s: %s" % (target.label, info.some_field if info else "none")
```

Provider keys are the fully qualified `<file>%<name>` form for Starlark
providers, and the plain name for built-ins like `DefaultInfo`.

**Generate an IDE or tooling manifest** - walk the graph once and emit JSON for
another tool to consume.

## Limitations

- No file I/O, no imports - it is ordinary Starlark
- `format` must return a string
- Runs after analysis, so it is as slow as `cquery`

## Key takeaway

`--output=starlark` turns `cquery` into a programmable interface to the
configured build graph. Use it instead of parsing text.
