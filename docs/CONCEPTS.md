# Bazel Concept Map

Where each concept is taught, and how the pieces relate.

## The mental model

```
LOADING      BUILD and .bzl files parse; macros expand; targets exist
   |         debug with: bazel query, print(), --output=build
ANALYSIS     rules run; select() resolves; toolchains resolve; ACTIONS are created
   |         debug with: bazel cquery, bazel config, analysistest
EXECUTION    only the actions needed for the requested targets actually run
             debug with: bazel aquery, --subcommands, --sandbox_debug
```

Almost every confusing Bazel error becomes clear once you identify which phase
it came from (sample 045).

## The core bargain

**You declare inputs and outputs honestly. Bazel gives you correctness,
caching, parallelism and reproducibility.**

Everything else follows:

| You get | Because |
|---------|---------|
| Correct incremental builds | Inputs are declared, so invalidation is exact |
| Caching (local and remote) | Same declared inputs = same cache key |
| Parallelism | The graph says what is independent |
| Remote execution | Actions are self-contained |
| Reproducibility | Nothing undeclared can influence the result |

Break the declaration discipline and you lose all five at once. That is why
samples 158 (sandboxing) and 160 (hermeticity) matter more than they look.

## Concept index

### Structure
| Concept | Samples |
|---------|---------|
| Packages, targets, labels | 001, 019, 044 |
| BUILD file anatomy, phases | 002, 045 |
| Visibility and encapsulation | 015, 016, 041, 046 |
| Target granularity | 018 |
| Repository layout | 165, 166 |

### Dependencies
| Concept | Samples |
|---------|---------|
| `deps` / `srcs` / `data` / `hdrs` | 003, 012, 021, 049 |
| Runfiles | 012, 040, 080, 081, 111 |
| Include paths | 022, 039 |
| External modules (bzlmod) | 035, 036, 066-071 |
| Overrides, local development | 068, 069 |
| Module extensions, repository rules | 070, 135-139 |

### Configuration
| Concept | Samples |
|---------|---------|
| `select()` and `config_setting` | 056-058, 089 |
| Build settings / custom flags | 059, 060, 140 |
| Platforms and constraints | 062-064, 128, 129, 170 |
| Compilation modes, `.bazelrc` | 025, 033, 034 |
| Transitions | 141-143 |

### Writing rules
| Concept | Samples |
|---------|---------|
| Macros (legacy and symbolic) | 051, 052, 096, 097, 194 |
| Rules, `ctx`, attributes | 101-103 |
| Actions | 104-109, 145, 146 |
| Providers | 110, 114, 115 |
| Depsets | 116-118, 190 |
| Output groups, validation | 119, 120 |
| Executable and test rules | 112, 113 |
| Toolchains | 123-127, 168, 169 |
| Aspects | 130-134 |
| Composition and wrapping | 197, 198 |

### Testing
| Concept | Samples |
|---------|---------|
| Test basics, size, tags | 004, 007, 026-028 |
| Sharding, flakiness, caching | 077, 078, 178, 179, 181 |
| Coverage | 079, 180 |
| Golden / diff tests | 087 |
| `build_test` | 088 |
| Starlark and analysis tests | 185-188 |
| Policy tests | 177 |

### Scale and operations
| Concept | Samples |
|---------|---------|
| Caching (disk, repository, remote) | 151-153, 184 |
| Remote execution | 154, 155 |
| Observability (BEP, profiles, logs) | 156, 157, 162, 176 |
| Sandboxing and strategies | 158, 159 |
| Hermeticity and reproducibility | 160, 161, 163 |
| Performance (loading, analysis, memory) | 189-193 |
| Packaging and release | 085, 086, 099, 171-173 |
| CI design | 182, 183 |

## The ten ideas that matter most

1. **Declared inputs are the whole system** (003, 158)
2. **Labels are global names**, which is what makes caching shareable (019)
3. **The three phases are distinct** - loading, analysis, execution (002)
4. **Targets are the unit of caching and parallelism** (018)
5. **`select()` resolves at analysis time**, not loading (056)
6. **Providers are the API between rules** (114)
7. **Depsets, not lists, for transitive data** (116, 190)
8. **Toolchains decouple rules from tools** (123, 169)
9. **Configuration is part of the output path**, so variants coexist (025, 143)
10. **Hermeticity is the precondition for caching, remote execution and CI** (160)

## Common failure modes and where they are explained

| Symptom | Cause | Sample |
|---------|-------|--------|
| `name 'cc_binary' is not defined` | Missing `load()` in Bazel 9 | 001, 199 |
| `no such target` for a file | File not `exports_files`'d | 017 |
| `not visible from target` | Visibility | 015 |
| `missing dependency declarations` | Undeclared header | 003, 021 |
| `$(VAR)` empty in a genrule | Forgot `$$` escaping | 010, 161 |
| Works locally, fails in CI | Undeclared input / environment | 158, 160, 161 |
| Low remote cache hit rate | Non-hermetic toolchain | 169, 184 |
| Analysis phase is slow | Configuration explosion or `to_list()` in a loop | 190, 193 |
| Test passes but code is broken | Cached result, undeclared input | 178 |
| `Argument list too long` | No param file | 146 |
