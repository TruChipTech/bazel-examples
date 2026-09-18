# 152 - The Repository Cache and Vendoring

**Concepts:** repository cache, `bazel vendor`, offline builds

## Try it

```bash
bazel info repository_cache
du -sh $(bazel info repository_cache)

bazel build //152_repository_cache:external_probe
cat bazel-bin/152_repository_cache/file_count.txt
```

## The repository cache

Every archive Bazel downloads is stored **content-addressed by its SHA256**, in
a cache shared across *all* workspaces on the machine:

```
~/.cache/bazel/_bazel_<user>/cache/repos/v1/content_addressable/sha256/<hash>/file
```

Consequences worth knowing:

- Two workspaces needing the same `http_archive` download it **once**.
- `bazel clean --expunge` deletes the external repo *directories* but not the
  cache, so re-fetching is a copy rather than a download.
- **This is why `sha256` matters.** Without it Bazel cannot address the content,
  so it cannot reuse the cache entry and must re-download.

## Controlling it

```bash
bazel build //... --repository_cache=/shared/bazel-repo-cache
bazel build //... --repository_cache=      # disable
```

A shared network path works and is a cheap win for a CI fleet.

## Vendoring for offline builds

```bash
# Fetch everything into a directory you control
bazel vendor --vendor_dir=vendor_src //...

# Build using only what was vendored - no network at all
bazel build --vendor_dir=vendor_src //...
```

`bazel vendor` materializes every external repository as real directories.
Commit that directory (or archive it) and the build no longer needs the
network or the Bazel Central Registry.

## When vendoring is worth the cost

| Situation | Why |
|-----------|-----|
| Air-gapped build environments | There is no network |
| Regulatory / supply-chain review | Every external byte is in your repo |
| Long-term reproducibility | Upstream disappearing cannot break old commits |
| Flaky CI networks | Removes a whole class of failure |

The cost is real: a large vendor directory bloats the repo and every dependency
update becomes a large diff. Most teams rely on the lockfile plus an internal
mirror instead, and vendor only when a policy demands it.

## Related offline flags

```bash
bazel build //... --nofetch                 # fail rather than fetch anything new
bazel fetch //...                           # pre-fetch, then build offline
bazel sync --configure                      # refresh configure-like repositories
```

A common CI pattern is `bazel fetch //...` as a separate, retryable step, so a
network blip fails fast in a step designed to be retried rather than in the
middle of a long build.

## Key takeaway

The repository cache is shared and content-addressed - always set `sha256`.
`bazel vendor` gives a genuinely offline build when policy requires it.
