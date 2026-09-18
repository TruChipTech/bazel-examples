# 140 - Reading Build Settings in a Rule

**Concepts:** `BuildSettingInfo`, `ctx.var`, flag-driven rules

## Run it

```bash
B=//140_build_settings_in_rules
P=//140_build_settings_in_rules

bazel build $B:service
cat bazel-bin/140_build_settings_in_rules/service.conf

bazel build $B:service --$P:opt_level=3 --$P:tracing=true
cat bazel-bin/140_build_settings_in_rules/service.conf
```

## The pattern

```python
"_opt_level": attr.label(default = Label("//pkg:opt_level")),

# in the implementation:
value = ctx.attr._opt_level[BuildSettingInfo].value
```

The rule depends on the flag **target**; the flag's value arrives through
`BuildSettingInfo`. Because it is a private attribute, callers cannot set it
per-target - it is a build-wide knob.

## select() vs reading the value

| | `select()` | Reading `BuildSettingInfo` |
|---|-----------|---------------------------|
| Where | BUILD file attributes | Rule implementation |
| Can express | "use this value instead of that" | Arbitrary logic |
| Needs | A `config_setting` per branch | Nothing extra |
| Good for | Swapping deps, srcs, copts | Computing derived values |

`select()` needs one `config_setting` per possible value. If a flag has ten
values and you want to compute something from it, reading the value in the
implementation is far cleaner:

```python
flags = ["-O" + opt_level]
if tracing:
    flags.append("-DENABLE_TRACING")
```

Expressing that with `select()` would require a combinatorial set of
`config_setting`s.

## `ctx.var`

```python
mode = ctx.var.get("COMPILATION_MODE", "unknown")
```

`ctx.var` holds Make variables, including toolchain-provided ones and
`--define` values. Use `.get()` with a default - a missing key otherwise
crashes the rule.

## Configuration is still part of the cache key

Reading a flag does not bypass caching. The flag's value is part of the
configuration, so `--opt_level=2` and `--opt_level=3` produce separately-cached
results with different output paths. Changing a flag does not invalidate the
other value's cache.

## Key takeaway

`attr.label` pointing at the flag, plus `BuildSettingInfo`, lets a rule compute
from a flag rather than merely switching on it.
