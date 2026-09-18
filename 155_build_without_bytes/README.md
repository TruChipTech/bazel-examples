# 155 - Build Without the Bytes

**Concepts:** `--remote_download_*`, output materialization

## The problem

With remote caching or execution, every action result is downloaded to your
machine - including intermediate artifacts nobody ever opens. A large C++ build
produces gigabytes of `.o` files that exist only to be fed to a linker that
also runs remotely.

Downloading them all makes the network the bottleneck, and a fast remote cache
ends up slower than building locally.

## The download policies

```bash
build --remote_download_minimal    # only what you explicitly requested
build --remote_download_toplevel   # top-level outputs + what tests need
build --remote_download_all        # everything (the old default)
```

| Policy | Downloads | Use when |
|--------|-----------|----------|
| `minimal` | Almost nothing | CI - nobody inspects intermediates |
| `toplevel` | Final binaries and test logs | Developer machines |
| `all` | Everything | Debugging the build itself |

`toplevel` is the sensible developer default: you get the binary you asked for
and the test logs you need, and nothing else crosses the network.

## Outputs become "remote" references

Under `minimal`, `bazel-bin/path/to/thing` may not exist locally - Bazel tracks
it as a remote reference. So this fails:

```bash
bazel build //x:y --remote_download_minimal
ls bazel-bin/x/y            # may not be there
```

Materialize on demand:

```bash
bazel build //x:y --remote_download_outputs=toplevel
```

Or use `bazel run`, which materializes what it needs.

## The failure mode to know about

If the remote cache evicts a blob that Bazel is still tracking as a remote
reference, you get:

```
ERROR: Failed to fetch blobs because they do not exist remotely
```

Recovery:

```bash
bazel build //... --experimental_remote_cache_eviction_retries=3
```

or simply re-run - Bazel re-executes the actions whose outputs vanished. Newer
Bazel versions handle this automatically, but on a cache with aggressive TTLs
it is worth knowing why it happened.

## Measuring the effect

```bash
bazel build //... --config=remote --remote_download_all 2>&1 | grep 'Network'
bazel build //... --config=remote --remote_download_minimal 2>&1 | grep 'Network'
```

Also visible in the BEP (sample 156) and in the profile's network lanes
(sample 157).

## Key takeaway

With any remote setup, set a download policy. `minimal` for CI, `toplevel` for
developers - otherwise you pay to download artifacts nobody reads.
