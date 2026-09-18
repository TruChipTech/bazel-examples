# 057 - config_setting in Depth

**Concepts:** `values`, `define_values`, `constraint_values`, specificity

## Run it

```bash
A=//057_config_setting:app

bazel run $A                                   # standard
bazel run $A -c dbg                            # standard-debug
bazel run $A -c opt                            # standard-optimized
bazel run $A --define=flavor=premium           # premium
bazel run $A --define=flavor=premium -c opt    # premium-optimized
```

## The four matchers

| Attribute | Matches | Example |
|-----------|---------|---------|
| `values` | Built-in Bazel flags | `{"compilation_mode": "opt"}` |
| `define_values` | `--define` values | `{"flavor": "premium"}` |
| `constraint_values` | Platform constraints | `["@platforms//os:linux"]` |
| `flag_values` | Custom build settings | `{":my_flag": "true"}` |

Conditions **within one** `config_setting` are ANDed. For OR, see sample 090.

## The specificity rule

`--define=flavor=premium -c opt` matches both `:premium` and `:premium_opt`.
Normally two matches is an error:

```
ERROR: Illegal ambiguous match on configurable attribute
```

Bazel allows it here because `:premium_opt` is a strict **specialization** of
`:premium` - it has all of `:premium`'s conditions plus more. The most specific
match wins. If neither setting is a superset of the other, you get the error
and must disambiguate.

## Where to put config_settings

Shared ones belong in a single well-known package, conventionally
`//build_settings` or `//bazel/config`, with public visibility. Redefining
`:opt_build` in forty packages is how you end up with forty subtly different
definitions.

## Key takeaway

`config_setting` is a named predicate over the configuration. `select()` is the
switch statement that consumes it.
