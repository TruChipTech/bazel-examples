# 200 - Capstone: A Production Pipeline

**Concepts:** everything in this repo, assembled into one system

## Run it

```bash
C=//200_capstone_production

bazel build $C/...
bazel test  $C:full

# One flag retargets the whole build:
bazel run $C/server:collector -- /tmp/batch.bin
bazel run $C/server:collector --//200_capstone_production:environment=prod -- /tmp/batch.bin

# The release artifact, with provenance:
bazel build --config=release $C:release
tar tzf bazel-bin/200_capstone_production/release.tar.gz
```

## The architecture

```
schema/       proto_library + cc_proto_library + py_proto_library
                  |                                    |
rules/        generated_config rule + ConfigInfo + analysis tests
toolchain/    config_toolchain_type + a registered implementation
                  |
server/       cc_binary: generated config + C++ proto bindings
client/       py_binary: Python proto bindings
tests/        analysis test + end-to-end test + policy test
BUILD         build setting, provenance manifest, packaging, release test
```

## What each layer contributes

| Layer | Samples | What it demonstrates |
|-------|---------|----------------------|
| `schema/` | 074-076, 098 | One contract, two languages, cannot drift |
| `rules/` | 101-119 | Custom rule, provider, `Args`, param files, validation action |
| `toolchain/` | 123-125 | The rule names no generator; resolution supplies one |
| `server/` | 048, 083 | Consuming a generated header via `cc_library` |
| `tests/` | 177, 186, 187 | Analysis + end-to-end + architectural policy |
| root `BUILD` | 059, 086, 092, 099 | Build setting, packaging, stamping, artifact verification |

## The five ideas worth keeping

**1. The schema is a build target.** Change `telemetry.proto` and both the C++
and Python bindings regenerate in the same build. `tests:e2e_test` depends on
both binaries, so a wire-format mismatch fails immediately rather than at
integration time.

**2. Configuration is resolved at build time, not startup.** The
`environment` flag drives a custom rule that generates a header. `collector.cc`
reads a `#define`; it has no idea a flag existed. The two variants are cached
separately.

**3. The rule names no tool.** `generated_config` asks for a toolchain type.
Swapping generators is a `toolchain()` registration, not a code change - the
same indirection that lets `cc_library` work on every platform.

**4. Tests cover three different things.** The analysis test checks the rule is
wired correctly without running anything. The e2e test checks the two languages
interoperate. The policy test checks the *dependency graph* has not grown an
edge it should not have. None of the three would catch the others' bugs.

**5. The release is a target, not a script.** `:release` is built, stamped with
its source commit, and verified by `:release_test` - which unpacks the tarball
and asserts the layout. "Ship it" is `bazel build --config=release //...:release`.

## The CI shape this enables

```bash
# presubmit: fast, analysis-only tests
bazel test //200_capstone_production:presubmit

# postsubmit: everything
bazel test //200_capstone_production:full

# release
bazel build --config=release //200_capstone_production:release
bazel test //200_capstone_production:release_test
```

## Try extending it

- Add a `staging` toolchain with a stricter generator and register it first.
- Add a transition (sample 141) so `:release` always builds `-c opt`.
- Add a lint aspect (sample 134) over the whole closure.
- Add `pkg_deb` (sample 172) alongside the tarball, reusing the same
  `pkg_files`.
- Add a `--platforms` matrix (sample 170) and ship per-architecture artifacts.

## You have finished the course

Across 200 samples you have gone from `cc_binary` to writing rule sets,
toolchains, aspects and transitions, and from `bazel build` to remote caching,
hermeticity, profiling and release engineering.

The thread running through all of it: **declare your inputs and outputs
honestly, and Bazel gives you correctness, caching, parallelism and
reproducibility for free.** Every scaling feature - remote caching, remote
execution, impact analysis - is just a consequence of that one discipline.
