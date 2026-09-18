# 184 - Operating a Remote Cache

**Concepts:** deployment, access control, diagnosing misses

## Running one

The simplest credible option is `bazel-remote`:

```bash
docker run -d -p 9092:9092 -p 8080:8080 \
  -v /srv/bazel-cache:/data \
  buchgr/bazel-remote-cache \
  --dir /data --max_size 100 --grpc_port 9092 --http_port 8080
```

```
build --remote_cache=grpc://cache.internal:9092
```

## Access control

```
# CI: read and write
build:ci --remote_cache=grpcs://cache.internal:9092
build:ci --remote_upload_local_results=true
build:ci --remote_header=authorization=Bearer ${CACHE_TOKEN}

# Developers: read only
build --remote_cache=grpcs://cache.internal:9092
build --noremote_upload_local_results
```

Read-only for developers is the important half. A single machine with an odd
local toolchain, a modified system header, or a half-applied patch can
otherwise write results that everyone else then consumes.

## Making it fail softly

```
build --remote_local_fallback       # cache down -> build locally
build --remote_timeout=60s          # do not hang
build --remote_retries=3
```

Without `--remote_local_fallback`, a cache outage becomes a company-wide build
outage.

## Diagnosing a low hit rate

```bash
bazel build //... 2>&1 | tail -3
# INFO: 512 processes: 30 remote cache hit, 482 linux-sandbox.
```

30 out of 512 when it should be near-total. In order of likelihood:

**1. Non-hermetic toolchain.** Each machine's compiler differs, so every
compile action's key differs. This is the number-one cause. Fix: a hermetic
toolchain (sample 169).

**2. Host-specific `--action_env`.** `PATH`, `HOME`, `USER` (sample 161).

**3. Bazel version mismatch.** Pin `.bazelversion`.

**4. Different flags.** CI builds `-c opt`, developers `fastbuild`. Different
configurations legitimately do not share.

**5. Non-deterministic outputs.** Timestamps, paths, unsorted iteration
(sample 163).

Confirm which by diffing execution logs from two machines (sample 162):

```bash
# on CI and locally
bazel build //some:target --execution_log_json_file=/tmp/side.json
diff <(jq -S . /tmp/ci.json) <(jq -S . /tmp/local.json)
```

The first differing field names the cause exactly.

## Sizing and eviction

Caches are LRU and will fill. Rules of thumb:

- Size it for several days of build output, not hours
- Watch the eviction rate; heavy eviction means the cache is too small to help
- With `--remote_download_minimal` (sample 155), aggressive eviction can cause
  "blobs do not exist remotely" errors

## Is it working?

Track the hit rate per build from the BEP (sample 176) and graph it. A
regression shows up there days before anyone complains that builds feel slow.

## Key takeaway

CI writes, developers read, fall back locally on failure, and diagnose low hit
rates with an execution-log diff rather than by guessing.
