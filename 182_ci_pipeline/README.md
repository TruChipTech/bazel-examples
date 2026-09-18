# 182 - Designing a CI Pipeline

**Concepts:** presubmit/postsubmit, caching, configs

## The `.bazelrc` foundation

Put the pipeline's behavior in the repo, not in the CI YAML:

```
# CI baseline
build:ci --announce_rc
build:ci --show_timestamps
build:ci --keep_going
build:ci --build_event_json_file=bep.json
build:ci --lockfile_mode=error
build:ci --remote_cache=grpcs://cache.internal:9092
build:ci --remote_local_fallback

# Presubmit: fast, gates the merge
build:presubmit --config=ci
test:presubmit --test_tag_filters=-integration,-slow,-manual
test:presubmit --test_output=errors

# Postsubmit: complete, populates the cache
build:postsubmit --config=ci
build:postsubmit --remote_upload_local_results=true
test:postsubmit --test_output=errors

# Release
build:release_ci --config=ci
build:release_ci -c opt
build:release_ci --stamp
build:release_ci --workspace_status_command=./tools/workspace_status.sh
```

CI then runs one short command per stage, and changing the pipeline is a
reviewed code change rather than a YAML edit.

## The stages

```yaml
presubmit:
  - bazel test //... --config=presubmit

postsubmit:
  - bazel test //... --config=postsubmit

nightly:
  - bazel test //... --config=ci --runs_per_test=5 --nocache_test_results
  - bazel coverage //... --config=ci --combined_report=lcov

release:
  - bazel build //...:release --config=release_ci
```

## The rules that make it work

**1. Only CI writes to the remote cache.**
```
build:postsubmit --remote_upload_local_results=true     # CI
build --noremote_upload_local_results                   # developers
```
One machine with a broken toolchain can otherwise poison the cache for
everyone.

**2. Never hard-code target lists.** Use `//...` with tag filters, or a
`test_suite`. Hard-coded lists drift within weeks (sample 179).

**3. Pin the Bazel version.** `.bazelversion`, read by bazelisk. Different
versions mean different cache keys - CI and developers stop sharing anything.

**4. `--keep_going` in CI, not locally.** Developers want to fix the first
error; CI wants the full list.

**5. Fail on a stale lockfile.**
```
build:ci --lockfile_mode=error
```

**6. Emit the BEP and record metrics** (samples 156, 176). Cache hit rate over
time is your early-warning system.

## Caching in ephemeral runners

Container-based runners start empty, which defeats the local action cache. What
to persist, in priority order:

| Directory | Value |
|-----------|-------|
| Remote cache (not a directory) | **Highest** - shared across all runners |
| `~/.cache/bazel/.../cache/repos` (repository cache) | Avoids re-downloading |
| `--disk_cache` directory | Useful if there is no remote cache |
| The whole output base | Rarely worth it; large and version-sensitive |

A remote cache plus a persisted repository cache gets most of the benefit.

## Bazel's exit codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Build failed |
| 2 | Command-line problem |
| 3 | **Tests failed** (the build succeeded) |
| 4 | No tests found |
| 8 | Build interrupted |

Exit 3 vs 1 matters: it lets CI distinguish "your code does not compile" from
"your tests fail", and report them differently.

## Key takeaway

Encode the pipeline in `.bazelrc` configs, give CI exclusive cache-write
access, use tag filters rather than target lists, and track the BEP.
