# 150 - Capstone: A Complete Rule Set

**Concepts:** everything from 101-149 assembled

## Run it

```bash
C=//150_capstone_rule_set

bazel build $C/...
bazel run   $C/project:pizza
bazel test  $C:all_tests

# The optional output group:
bazel build $C/project:dough --output_groups=manifest
cat bazel-bin/150_capstone_rule_set/project/dough.manifest

# The lint aspect, via its report rule:
bazel build $C/project:lint
cat bazel-bin/150_capstone_rule_set/project/lint.summary
```

## The layout

```
150_capstone_rule_set/
  rules/       providers.bzl, toolchain.bzl, defs.bzl   the rule set
  toolchain/   compile.py, lint.py + toolchain wiring   the implementation
  project/     .recipe sources + targets                a user of the rule set
```

That three-way split is how real rule sets are organized: the **rules** know
nothing about any specific compiler, the **toolchain** supplies one, and the
**project** uses the rules without naming either.

## What each piece demonstrates

| Concept | Sample | Where |
|---------|--------|-------|
| Custom providers | 114 | `RecipeInfo`, `RecipeLintInfo` |
| Provider-typed deps | 103 | `attr.label_list(providers = [RecipeInfo])` |
| Transitive depsets | 116-118 | `_collect()`, shared by all three rules |
| `ctx.actions.run` | 105 | `RecipeCompile` |
| `Args` + param files | 145-146 | The compiler's command line |
| Executable rules + runfiles | 111-112 | `recipe_binary` |
| Custom test rules | 113 | `recipe_test` |
| Output groups | 119 | `manifest` |
| Toolchains | 123-125 | `recipe_toolchain_type`, registered in MODULE.bazel |
| `files_to_run` | 124 | Carrying the compiler and linter |
| Aspects | 130-134 | `recipe_lint_aspect` |
| Aspect from a rule | 132 | `recipe_lint_report` |
| Transitive output groups | 133 | Lint reports aggregate up the graph |

## The two ideas worth carrying forward

**1. The rules never name a compiler.** `recipe_library` asks for a toolchain
type. Swapping in a different compiler is a `toolchain()` registration, not a
code change. This is exactly how `cc_library` works.

**2. The closure is computed once and shared.** `_collect()` is used by the
library, the binary and the test, so all three agree on what "transitive
closure" means. Flattening happens only in the binary, at the leaf.

## Try extending it

- Add a `recipe_toolchain` with a stricter linter and register it first.
- Add an output group for a generated shopping list.
- Add a transition so `recipe_binary` always builds its deps in `-c opt`.
- Make the lint reports a `_validation` output group (sample 120) so they run
  on every build.

## Where this leads

With rules, providers, aspects, toolchains and transitions you can build the
kind of tooling that other people's BUILD files depend on.

Samples 151-200 cover running that at scale: caching, remote execution,
profiling, hermeticity and CI.
