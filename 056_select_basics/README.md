# 056 - select(): Configurable Attributes

**Concepts:** `select()`, `config_setting`, `//conditions:default`

## Run it

```bash
bazel run //056_select_basics:platform_info
```

On Linux this prints `built for: linux`.

## What select() actually is

`select()` returns a special object, not a list. Bazel resolves it during
**analysis**, once it knows the configuration. That is why this works:

```python
copts = select({":on_linux": ["-pthread"], "//conditions:default": []})
```

and this does not:

```python
if on_linux:              # there is no "on_linux" variable at loading time
    copts = ["-pthread"]  # the configuration is not known yet
```

## Concatenation

You can add a plain list to a select, and add selects together:

```python
copts = ["-Wall"] + select({
    ":on_linux": ["-pthread"],
    "//conditions:default": [],
})
```

The unconditional part applies everywhere; the select contributes the rest.

## `//conditions:default`

Without a default, a configuration matching no branch is a hard error:

```
ERROR: Configurable attribute "copts" doesn't match this configuration
```

That is sometimes exactly what you want - it prevents silently building for an
unsupported platform. Add a custom message with `no_match_error` (sample 058).

## Multiple matches

If two `config_setting`s both match, Bazel errors unless one is a strict
specialization of the other. Sample 090 covers `selects.config_setting_group`
for AND/OR conditions.

## Where select works

Most attributes, but **not** `name`, `visibility`, or the attributes of a
`config_setting` itself. Rule authors mark an attribute non-configurable
deliberately (sample 052).

## Key takeaway

`select()` is how one BUILD file describes many configurations. The branch is
chosen at analysis time, so each configuration gets its own cached result.
