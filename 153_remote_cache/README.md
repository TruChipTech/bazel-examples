# 153 - Remote Caching

**Concepts:** `--remote_cache`, cache keys, CI/developer sharing

## Configuration

```
# .bazelrc
build:remote-cache --remote_cache=grpc://cache.internal:9092
build:remote-cache --remote_upload_local_results=true
build:remote-cache --remote_timeout=60s
```

```bash
bazel build //... --config=remote-cache
```

Supported endpoints: `grpc://`, `grpcs://`, `http://`, `https://`.

## What gets shared

An action's cache key is a hash of:

- The command line
- The contents of every declared input
- The declared environment variables
- The execution platform and properties

If two machines compute the same key, they can share the result. That is the
entire mechanism - and it is also why **undeclared inputs are so damaging**:
they change the output without changing the key, so a poisoned entry gets
served to everyone.

## The standard topology

```
CI  --(writes)--> remote cache <--(reads only)--  developers
```

CI has write access; developers read. A developer pulling `main` then gets a
build that is almost entirely cache hits, because CI already built that commit.

Developer write access is usually a mistake: one machine with a broken local
toolchain can poison entries for the whole team.

```
# developer .bazelrc
build --remote_cache=grpcs://cache.internal:9092
build --noremote_upload_local_results
```

## Making it not hurt

```
# Do not let a cache outage fail the build
build --remote_local_fallback

# Bound the wait
build --remote_timeout=60s

# Do not upload results from actions marked no-remote-cache
build --incompatible_remote_results_ignore_disk=true
```

`--remote_local_fallback` is the important one: without it, an unreachable
cache turns into a build failure for everyone.

## Verifying you are actually getting hits

```bash
bazel build //... --config=remote-cache 2>&1 | tail -3
# "INFO: 512 processes: 498 remote cache hit, 14 linux-sandbox."
```

If the hit rate is near zero when it should be high, the usual causes are:

| Cause | Fix |
|-------|-----|
| Absolute paths baked into commands | Use `--experimental_convenience_symlinks`, relative paths |
| Timestamps or hostnames in outputs | Strip them; see sample 163 |
| `--action_env` differing per machine | Declare only what is needed |
| Different Bazel versions | Pin `.bazelversion` |
| Different toolchain (local gcc) | Use a hermetic toolchain (sample 169) |

That last one is the most common: if each machine uses its own system compiler,
the cache keys differ and nothing is ever shared.

## Implementations

| Server | Notes |
|--------|-------|
| `bazel-remote` | Open source, simple, self-hosted |
| BuildBuddy | Hosted or self-hosted, with a UI |
| EngFlow | Commercial, cache + execution |
| `nativelink` | Open source, Rust |
| Google Cloud / AWS S3 via HTTP proxies | Works, but slower |

## Key takeaway

Remote caching turns CI's work into everyone's speedup. It only works if your
builds are hermetic - which is what makes sample 160 worth reading before you
turn it on.
