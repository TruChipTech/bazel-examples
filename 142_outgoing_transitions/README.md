# 142 - Outgoing and Split Transitions

**Concepts:** `cfg` on an attribute, split transitions, `ctx.split_attr`

## Run it

```bash
bazel build //142_outgoing_transitions:bundle
cat bazel-bin/142_outgoing_transitions/bundle.bundle
```

One `channel_probe` target appears four times in the output - three channels
plus a debug build. The BUILD file lists it twice.

## The two kinds

**Outgoing 1:1** - the dependency is built in a different configuration:

```python
"debug_variant": attr.label(cfg = _debug_dep),
```

**Gotcha:** even a 1:1 transition makes the attribute arrive as a **list**:

```python
ctx.attr.debug_variant[DefaultInfo]      # ERROR: got Provider for sequence index, want int
ctx.attr.debug_variant[0][DefaultInfo]   # correct
```

Bazel cannot tell from the schema whether a transition is 1:1 or a split, so
any `cfg`-carrying label attribute is a list. This error message is cryptic the
first time you see it.

**Split** - the dependency is built **once per key**:

```python
def _impl(settings, attr):
    return {
        "alpha":  {"//pkg:channel": "alpha"},
        "beta":   {"//pkg:channel": "beta"},
        "stable": {"//pkg:channel": "stable"},
    }
```

Accessed through `ctx.split_attr`:

```python
for key, targets in ctx.split_attr.variants.items():
    ...
```

## Where split transitions are used for real

- **Universal binaries.** Build for arm64 and x86_64, then `lipo` them
  together. This is exactly how Apple platform rules work.
- **Multi-ABI Android APKs.** One APK containing native libraries for several
  architectures.
- **Multi-arch container images.** One manifest, several platform layers.

In each case the final rule needs *several configurations of the same
dependency* simultaneously - something no other mechanism provides.

## Incoming vs outgoing

| | Incoming (`cfg` on the rule) | Outgoing (`cfg` on an attribute) |
|---|------------------------------|----------------------------------|
| Affects | This target and everything below | Only that attribute's deps |
| Declared on | `rule(cfg = ...)` | `attr.label(cfg = ...)` |
| Use for | "this target has a fixed config" | "this dependency needs a different config" |

## Reading the current value

```python
def _impl(settings, attr):
    current = settings["//command_line_option:compilation_mode"]
    return {"//command_line_option:compilation_mode": "opt" if current == "fastbuild" else current}
```

List the flag in `inputs` to read it. This is how conditional transitions work.

## Cost, again

A split transition with three keys builds that subgraph **three times**.
Analysis time and memory scale with the number of distinct configurations, so
keep the split near the leaves of the graph where possible.

## Key takeaway

`cfg` on an attribute changes the dependency's configuration; returning a dict
of dicts builds it several ways, read back through `ctx.split_attr`.
