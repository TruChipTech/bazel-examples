# 151 - The Disk Cache

**Concepts:** `--disk_cache`, action cache vs disk cache

## Try it

```bash
D=//151_disk_cache
CACHE=/tmp/bazel-disk-cache-demo

# Populate the cache
bazel build $D:app --disk_cache=$CACHE
du -sh $CACHE

# Throw away all build outputs, then rebuild from the cache
bazel clean
time bazel build $D:app --disk_cache=$CACHE

# Compare with no cache at all
bazel clean
time bazel build $D:app --disk_cache=
```

The cached rebuild does no compilation - Bazel recognizes each action's cache
key and copies the result.

## The three caches, which people constantly conflate

| Cache | Lives | Survives | Holds |
|-------|-------|----------|-------|
| **Analysis cache** | In the Bazel server's memory | Until `bazel shutdown` or a flag change | The configured target graph |
| **Action cache** | `bazel-out/`, per output base | `bazel clean` destroys it | "this action already ran here" |
| **Disk cache** | A directory you choose | `bazel clean` does **not** touch it | Action *results*, content-addressed |

`bazel clean` wipes outputs and the action cache but not the disk cache, which
is exactly why the second build above is fast.

## Turning it on

```
# .bazelrc
build --disk_cache=~/.cache/bazel-disk-cache
```

This repo has it under a config:

```
build:cached --disk_cache=~/.cache/bazel-disk-cache
```

## Where it actually pays off

- **Switching branches.** Going back to a branch you built an hour ago reuses
  everything.
- **Multiple checkouts.** Several worktrees of the same repo share one cache.
- **After `bazel clean`.** Which people do far more often than they should.
- **Configuration switching.** `-c opt` then `-c dbg` then back.

## It grows without bound

Bazel does **not** garbage-collect the disk cache automatically in older
versions. Prune it:

```bash
# Delete entries not accessed in 30 days
find ~/.cache/bazel-disk-cache -type f -atime +30 -delete
```

Newer Bazel supports `--experimental_disk_cache_gc_max_size`; check
`bazel help build | grep disk_cache` for what your version offers.

## Disk cache vs remote cache

The disk cache is a local, single-machine remote cache. Everything you learn
here transfers directly to sample 153 - the cache key computation and the
hit/miss semantics are identical, only the storage differs.

## Key takeaway

`--disk_cache` is one line for a large win on any machine where you clean,
switch branches, or keep several checkouts.

## Proving the cache is actually used

`bazel clean` is a blunt way to test this. A cleaner experiment uses a fresh
**output base**, which has no action cache at all, so any hit must have come
from the disk cache:

```bash
bazel --output_base=/tmp/fresh-ob build //151_disk_cache:app \
  --disk_cache=/tmp/bazel-disk-cache-demo
```

```
INFO: 9 processes: 4 disk cache hit, 5 internal.
```

Bazel reports `disk cache hit` explicitly in the process summary. If you see
`linux-sandbox` counts where you expected hits, the cache is not being used -
check the path, and check that nothing about the action's inputs or command
line differs between the two runs.

Remember to `bazel --output_base=/tmp/fresh-ob shutdown` afterwards; each
output base runs its own server and holds memory.
