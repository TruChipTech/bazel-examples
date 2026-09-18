# 023 - Compiler Options and Preprocessor Defines

**Concepts:** `copts`, `defines`, `local_defines`

## Run it

```bash
bazel run //023_copts_defines:feature
bazel run //023_copts_defines:plain
```

The same source file produces two different programs, because the flags are
part of the target, not the file.

## copts vs defines vs local_defines

| Attribute | Applies to | Propagates to consumers? |
|-----------|-----------|--------------------------|
| `copts` | This target's compile actions | No |
| `local_defines` | This target only, as `-D` | No |
| `defines` | This target **and everything that depends on it** | **Yes** |

`defines` is the dangerous one. It is occasionally necessary - when a header's
meaning genuinely depends on a macro - but it leaks into every transitive
consumer and causes ODR violations when two libraries disagree. Reach for
`local_defines` first.

## Flags are part of the cache key

Change a `copt` and Bazel rebuilds, because the compile action's command line
changed. This is why two targets with identical `srcs` but different `copts`
are correctly cached separately, as `feature` and `plain` demonstrate.

## Repo-wide flags

Do not repeat `-Wall` on 500 targets. Put it in `.bazelrc`:

```
build --copt=-Wall --copt=-Wextra
```

## Key takeaway

`copts` are per-target and private. `defines` are contagious - use sparingly.
