# 163 - Verifying Reproducible Builds

**Concepts:** bit-for-bit reproducibility, verification techniques

## Try it

```bash
R=//163_reproducible_builds

bazel build $R:deterministic
sha256sum bazel-bin/163_reproducible_builds/deterministic > /tmp/h1

bazel clean
bazel build $R:deterministic
sha256sum bazel-bin/163_reproducible_builds/deterministic > /tmp/h2

diff /tmp/h1 /tmp/h2 && echo "REPRODUCIBLE"
```

Then try the deliberately broken one:

```bash
bazel build $R:nondeterministic --nocache_test_results
cat bazel-bin/163_reproducible_builds/nondeterministic.txt
# a different number every time
```

## The three levels

| Level | Means |
|-------|-------|
| **Incremental correctness** | Rebuilding after a change gives the right answer |
| **Cacheable** | Same inputs, same cache key - the basis of sharing |
| **Bit-for-bit reproducible** | Same inputs, byte-identical outputs |

Bazel gives you the first two if you are hermetic. The third additionally
requires your *tools* to be deterministic, which is usually the harder half.

## What Bazel already does for you

- Scrubs the environment (sample 161)
- Sandboxes actions (sample 158)
- Redacts `__DATE__`, `__TIME__`, `__TIMESTAMP__` in C++
- Sorts runfiles and archive entries
- Uses a fixed timestamp in `pkg_tar` outputs

## What you still have to handle

| Source | Fix |
|--------|-----|
| Timestamps in generated code | Use the commit SHA (sample 092) |
| Build paths in debug info | `-fdebug-prefix-map`, `-ffile-prefix-map` |
| Hash-order iteration | Sort before emitting; `PYTHONHASHSEED=0` |
| Parallel output interleaving | Collect and sort, or write per-worker files |
| Random seeds / UUIDs | Derive them from the inputs |
| Archive mtimes and ownership | `pkg_tar` handles this; check your own tools |

## Verification techniques, in increasing strength

**1. Same machine, two builds**
```bash
bazel build //x:y && sha256sum bazel-bin/x/y
bazel clean && bazel build //x:y && sha256sum bazel-bin/x/y
```

**2. Different output bases** - catches path dependence
```bash
bazel --output_base=/tmp/ob1 build //x:y
bazel --output_base=/tmp/ob2 build //x:y
```

**3. Execution log diff** - catches *which* action differs (sample 162)

**4. Two machines / two users** - the real test, and the one that catches
absolute paths in debug info

## Why bother

- **Supply chain.** You can prove the binary matches the source.
- **Caching.** Non-determinism silently destroys cache hit rates.
- **Debugging.** "It only fails in CI" usually means "the build differs in CI".

## Key takeaway

Reproducibility is verifiable, not aspirational. Diff hashes across output
bases and machines; diff execution logs when they disagree.
