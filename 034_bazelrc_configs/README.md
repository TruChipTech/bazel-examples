# 034 - Named Configurations with --config

**Concepts:** `--config`, `build:<name>`, flag bundles

## Run it

```bash
bazel run //034_bazelrc_configs:app
bazel run --config=dev     //034_bazelrc_configs:app
bazel run --config=release //034_bazelrc_configs:app
```

## How it works

Any rc line of the form `build:NAME --flag` is **inactive** until someone
passes `--config=NAME`. From this repo's `.bazelrc`:

```
build:dev -c fastbuild
build:dev --strip=never

build:release -c opt
build:release --stamp
build:release --workspace_status_command=./tools/workspace_status.sh

test:verbose --test_output=all
test:verbose --nocache_test_results
```

## Configs compose

```bash
bazel test --config=release --config=verbose //...
```

Both expand; later flags win on conflict.

## Configs can include other configs

```
build:ci --config=release
build:ci --jobs=64
build:ci --remote_cache=grpc://cache.internal:9092
```

Now CI runs `bazel test --config=ci //...` and the definition of "what CI does"
lives in the repo, reviewed like any other code.

## The real benefit

A config turns tribal knowledge ("remember to pass these six flags for a
release build") into a single reviewable name. When the flags need to change,
you change them in one place and every consumer picks it up.

## Key takeaway

If you ever type more than two flags together twice, make it a `--config`.
