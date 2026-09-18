# 020 - alias: A Stable Name for a Moving Target

**Concepts:** `alias`, indirection, migration

## Run it

```bash
bazel run //020_alias:main

# The alias resolves to the real target:
bazel query --output=build //020_alias:impl
```

## Why alias exists

Suppose 200 targets depend on `//lib:json`. You want to swap the
implementation. Without an alias that is a 200-file change. With one, it is a
single line:

```python
alias(name = "json", actual = ":json_v3")
```

## The three big uses

1. **Migration.** Point the alias at the old target, move consumers to the
   alias, then flip the alias once.
2. **Short names.** `//:app` can alias
   `//services/frontend/cmd/server:server_binary`.
3. **Conditional targets.** Combine with `select()` so one name resolves to a
   different implementation per platform (sample 065):

   ```python
   alias(
       name = "crypto",
       actual = select({
           ":linux":   ":crypto_openssl",
           ":macos":   ":crypto_commoncrypto",
       }),
   )
   ```

## Alias is free

It creates no actions and adds no build cost - it is resolved during analysis.

## Key takeaway

`alias` decouples the *name* a dependency is known by from the *target* that
implements it. That indirection is what makes large-scale refactors tractable.
