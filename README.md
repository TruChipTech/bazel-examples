# Bazel, by example

These are my notes from working through the Bazel build system - 225 small,
self-contained examples I wrote while figuring out how each piece actually
behaves, rather than how the documentation says it behaves.

I kept them because writing the example was usually what made the concept
stick, and because a lot of them encode a mistake I made first. Sharing them in
case they save someone else the same detour.

Everything here is real and runs:

```bash
bazel build //...          # every example
bazel test  //...          # every test
```

Built and verified with **Bazel 9.2.0**.

## How the examples are organised

All 225 sit at the repository root, numbered `001_` upward, so they sort in
reading order and every label stays short (`//003_cc_library_deps:math_utils`).
The numbering is roughly the order I learned things in - earlier examples
assume less - but each one stands alone, so jumping straight to whatever you
need is fine.

```
001_hello_world/          <- example 001
002_build_file_anatomy/   <- example 002
...
200_capstone_production/  <- example 200

MODULE.bazel              every external dependency, declared once
MODULE.bazel.lock         committed, for reproducible resolution
.bazelrc                  shared flags and named --config bundles
.bazelversion             pins Bazel 9.2.0
.bazelignore              directories Bazel must not scan
BUILD.bazel               grouped test suites (below)
LICENSE                   MIT
tools/                    workspace status script, for stamping
docs/                     concept map and command cheatsheet
```

### About the `bazel-*` entries

After a build you will also see `bazel-bin`, `bazel-out`, `bazel-testlogs` and
`bazel-bazel` in the root. **These are not examples and not real directories** -
they are symlinks Bazel creates into its cache under `~/.cache/bazel/`, and they
are already in `.gitignore`. Many examples reference them (`cat bazel-bin/...`)
to show where build output lands.

`bazel clean` removes them; the next build recreates them.

### Running a group

The flat layout means there is no directory to point `bazel test` at, so the
root `BUILD.bazel` defines four suites by number range:

```bash
bazel test //:foundations   # 001-050
bazel test //:composition   # 051-100
bazel test //:authoring     # 101-150
bazel test //:operations    # 151-200
bazel test //:all_tests     # everything
```

Tests tagged `manual` are excluded from those suites on purpose - a few
examples ship a test that is *meant* to fail, to show what the failure looks
like.

## How to read an example

Each directory has a `BUILD.bazel`, its sources, and a `README.md` with the
idea, the exact commands, and the one thing worth remembering. Most of them
also name a specific line to delete or uncomment so you can watch the failure
the concept prevents - that part is usually more instructive than the working
version.

## A note on the environment

Bazel 9 dropped `WORKSPACE` entirely and removed the built-in language rules,
so every example loads them explicitly
(`load("@rules_cc//cc:defs.bzl", "cc_binary")`). If you are following an older
tutorial and things do not resolve, that is usually why.

`.bazelrc` also pins `CC=/usr/bin/gcc` (the machine I wrote these on has a
`ccache` shim that cannot write inside Bazel's sandbox) and uses
`remotejdk_21` (no local JDK). Both are harmless elsewhere, and the second is
a good idea regardless - [169](169_hermetic_toolchain/) explains why.

## Prerequisites

Everything is verified on **RHEL 9 / x86_64**, but nothing is distro-specific.

### Required

| Tool | Used for | Check |
|------|----------|-------|
| **Bazel 9.2.0** | everything | `bazel --version` |
| **gcc / g++** | the C and C++ examples | `gcc --version` |
| **python3** (3.9+) | Python examples and build tools | `python3 --version` |
| **GNU binutils** | `objcopy`, `objdump`, `readelf`, `ld` - firmware images | `objcopy --version` |
| **openssl** (3.x) | signing, verification, X.509 | `openssl version` |
| **tar / gzip / dd** | layers, archives, disk images | `tar --version` |

### Required for the image and media examples (351-400)

| Tool | Package (dnf) | Package (apt) |
|------|---------------|---------------|
| `cpio` | `cpio` | `cpio` |
| `mksquashfs` | `squashfs-tools` | `squashfs-tools` |
| `xorriso` | `xorriso` | `xorriso` |
| `mcopy`, `mformat` | `mtools` | `mtools` |

### Optional

| Tool | Used for | Without it |
|------|----------|------------|
| `jq` | reading BEP output (156, 162, 176) | those commands only |
| `dot` (graphviz) | rendering query graphs (094) | graph output is still written |
| `lcov` / `genhtml` | HTML coverage reports (180) | the raw `.dat` is still produced |
| `podman` | cross-checking image layouts | examples use their own validator |
| `gpg` | detached-signature examples | openssl examples still work |

### Not required

- **A JDK.** `.bazelrc` sets `--java_runtime_version=remotejdk_21`, so Bazel
  downloads one.
- **32-bit libc.** The firmware examples compile `-m32` but also `-nostdlib`,
  so they never need `crt1.o` or `glibc-devel.i686`. A hosted `gcc -m32`
  hello-world will fail on a machine without it; the freestanding builds here
  will not.
- **Docker or a container runtime.** Images are assembled as files.
- **A registry, network, or cloud account.** Everything builds offline once
  dependencies are fetched.
- **cosign.** The signing examples use `openssl` directly and explain where
  cosign would slot in.

## Setup

```bash
# RHEL / Fedora
sudo dnf install -y gcc gcc-c++ python3 binutils openssl \
                    cpio squashfs-tools xorriso mtools jq graphviz

# Debian / Ubuntu
sudo apt install -y build-essential python3 binutils openssl \
                    cpio squashfs-tools xorriso mtools jq graphviz
```

Install Bazel with [bazelisk](https://github.com/bazelbuild/bazelisk), which
reads `.bazelversion` and fetches the matching release automatically:

```bash
go install github.com/bazelbuild/bazelisk@latest   # or download a release binary
ln -s "$(command -v bazelisk)" ~/.local/bin/bazel
```

Then:

```bash
git clone <this repo> && cd bazel
bazel build //...     # first run fetches dependencies, ~90s
bazel test  //...
```

The first build downloads roughly 1.6 GB of dependencies (a JDK, CPython,
protobuf, zlib, rule sets) into a shared cache under `~/.cache/bazel`. Later
builds reuse it; `bazel clean --expunge` does not delete it.

### A note on the signing keys

There are **no keys in this repository**. The signing examples generate a
throwaway RSA and ECDSA keypair with a repository rule
(`251_signing_basics/keys.bzl`) the first time you build, cached per
workspace. Nothing beginning `-----BEGIN PRIVATE KEY-----` is ever
committed.

This needs `openssl` on PATH. If it is missing the signing examples fail
with a clear message rather than silently skipping.

## Where to start

| If you... | Start at |
|-----------|----------|
| Have never run Bazel | [001 Hello World](001_hello_world/) |
| Can read BUILD files but not write rules | [051 Legacy Macros](051_legacy_macros/) |
| Want to write a rule set | [101 Your First Custom Rule](101_simple_rule/) |
| Need to make a big repo fast | [151 The Disk Cache](151_disk_cache/) |
| Are migrating off WORKSPACE | [199 Migrating From WORKSPACE](199_workspace_migration/) |

---

## All 225 examples

### Foundations - the build graph  (001-050)

Targets, labels, dependencies, tests, visibility, globs, generated files, and the commands you run every day. This is what I had to get straight before anything else made sense.

`bazel test //:foundations`

**[001 &middot; Hello World](001_hello_world/)** - The smallest possible Bazel build: one source file, one rule, one executable.
  <br/><sub>`cc_binary`, targets, labels, `load()`</sub>

**[002 &middot; BUILD File Anatomy](002_build_file_anatomy/)** - `package()` sets file-wide defaults and must be the first call. Individual targets can override those defaults, as `visibility` does here.
  <br/><sub>phases, `package()`, attributes, Starlark</sub>

**[003 &middot; Libraries and Dependencies](003_cc_library_deps/)** - Dependencies are explicit. If a target needs a header, it must declare a `deps` edge to whichever target owns that header.
  <br/><sub>`cc_library`, `deps`, `hdrs` vs `srcs`</sub>

**[004 &middot; Writing a Test](004_cc_test/)** - Exit code 0 = pass. Everything else Bazel gives you - caching, parallelism, log capture - comes for free once that contract is met.
  <br/><sub>`cc_test`, exit codes, test caching</sub>

**[005 &middot; Python Binaries](005_py_binary/)** - `bazel run` builds *and* executes. `bazel build` only produces the launcher - useful when you want to inspect the output without running it.
  <br/><sub>`py_binary`, `main`, launcher scripts</sub>

**[006 &middot; Python Libraries](006_py_library/)** - A library target is a unit of reuse plus a unit of caching. Change `app.py` and only `app` rebuilds - `textlib` stays cached.
  <br/><sub>`py_library`, `imports`, transitive deps</sub>

**[007 &middot; Python Tests](007_py_test/)** - Choose `size` honestly. It is the main lever Bazel has for scheduling a large test suite without thrashing.
  <br/><sub>`py_test`, `unittest`, `size`</sub>

**[008 &middot; Shell Binaries](008_sh_binary/)** - `sh_binary` is the bridge between "we have a pile of shell scripts" and a fully declared build graph. It is often the first step in migrating a legacy repo.
  <br/><sub>`sh_binary`, wrapping existing scripts</sub>

**[009 &middot; Shell Tests and `data`](009_sh_test/)** - If a program reads a file at runtime, that file belongs in `data`. Forgetting this is the single most common cause of "works locally, fails in CI".
  <br/><sub>`sh_test`, `data`, runfiles, working directory</sub>

**[010 &middot; genrule: Running Arbitrary Commands](010_genrule/)** - genrule = declared inputs + declared outputs + a shell command. Anything undeclared is invisible to the command.
  <br/><sub>`genrule`, `cmd`, Make variables, `$@` / `$<`</sub>

**[011 &middot; filegroup: Naming a Set of Files](011_filegroup/)** - `filegroup` is the answer to "how do I refer to these N files as one thing".
  <br/><sub>`filegroup`, composition, indirection</sub>

**[012 &middot; Runfiles: Files Available at Runtime](012_data_and_runfiles/)** - `data` answers "what does this program need to *read* when it runs?" - and that question has to be answered explicitly, just like dependencies.
  <br/><sub>runfiles, `data`, build time vs run time</sub>

**[013 &middot; glob: Matching Files by Pattern](013_glob/)** - `glob()` is loading-time convenience, not a runtime feature. Prefer `allow_empty = False`.
  <br/><sub>`glob()`, `**`, `allow_empty`</sub>

**[014 &middot; glob Excludes](014_glob_excludes/)** - `exclude` is subtractive and applied after the includes. Use it to keep tests, generated files, and work-in-progress out of production targets.
  <br/><sub>`exclude`, separating tests from sources</sub>

**[015 &middot; Visibility: Enforcing Architecture](015_visibility/)** - Default to private. Grant the narrowest visibility that works - `__pkg__` over `__subpackages__` over `public`.
  <br/><sub>`visibility`, `__pkg__`, encapsulation</sub>

**[016 &middot; Package-Level Defaults](016_default_visibility/)** - Package defaults reduce repetition. Individual targets always win over the default, so you can open a package broadly and still lock down specific targets.
  <br/><sub>`package()`, `default_visibility`, inheritance</sub>

**[017 &middot; exports_files: Sharing Raw Files](017_exports_files/)** - Visibility applies to files, not just rules. `exports_files()` is how a package publishes a file for others to name directly.
  <br/><sub>`exports_files`, source-file visibility</sub>

**[018 &middot; Many Targets in One Package](018_multiple_targets/)** - Package = directory. Target = build unit. There is no rule that they map 1:1, and good repos have several targets per package.
  <br/><sub>target granularity, caching, parallelism</sub>

**[019 &middot; Label Syntax in Depth](019_labels/)** - A label is a global, location-independent name. That property is what makes `bazel build //...` and remote caching possible.
  <br/><sub>labels, wildcards, external repo references</sub>

**[020 &middot; alias: A Stable Name for a Moving Target](020_alias/)** - `alias` decouples the *name* a dependency is known by from the *target* that implements it. That indirection is what makes large-scale refactors tractable.
  <br/><sub>`alias`, indirection, migration</sub>

**[021 &middot; srcs vs hdrs vs deps](021_srcs_hdrs_deps/)** - `hdrs` is your published contract. Anything you might want to change without breaking callers belongs in `srcs`.
  <br/><sub>public interface, private headers, encapsulation</sub>

**[022 &middot; Controlling Include Paths](022_include_paths/)** - The include path is part of your public API. Set it explicitly so you can move directories without a repo-wide sed.
  <br/><sub>`strip_include_prefix`, `include_prefix`, `includes`</sub>

**[023 &middot; Compiler Options and Preprocessor Defines](023_copts_defines/)** - `copts` are per-target and private. `defines` are contagious - use sparingly.
  <br/><sub>`copts`, `defines`, `local_defines`</sub>

**[024 &middot; Link Options](024_linkopts/)** - `linkopts` bridge to the host system. Every one of them is a small hole in your build's hermeticity - use them knowingly.
  <br/><sub>`linkopts`, system libraries, linkstatic</sub>

**[025 &middot; Compilation Modes](025_compilation_modes/)** - `-c` selects a configuration, and configurations are cached independently. Always benchmark with `-c opt`; always debug with `-c dbg`.
  <br/><sub>`-c fastbuild|dbg|opt`, `NDEBUG`, output dirs</sub>

**[026 &middot; Test Size and Timeout](026_test_size_timeout/)** - `size` is a scheduling hint that happens to set a timeout. Use `timeout` to adjust the clock without lying about the resources.
  <br/><sub>`size`, `timeout`, scheduling</sub>

**[027 &middot; Test Tags and Filtering](027_test_tags/)** - Tags are how you carve one test suite into several audiences without maintaining separate lists.
  <br/><sub>`tags`, `--test_tag_filters`, special tags</sub>

**[028 &middot; test_suite: Grouping Tests](028_test_suite/)** - Give CI a stable label (`//:presubmit`, `//:nightly`) and change the membership in the BUILD file rather than in the CI config.
  <br/><sub>`test_suite`, tag-based suites, composition</sub>

**[029 &middot; Arguments and Environment Variables](029_args_and_env/)** - If a program needs an environment variable, declare it. Relying on ambient environment is the fastest way to a build that works only on your machine.
  <br/><sub>`args`, `env`, `env_inherit`, sandbox scrubbing</sub>

**[030 &middot; Where Outputs Go](030_output_locations/)** - Outputs live outside the source tree, keyed by configuration. Never edit anything under `bazel-bin`; it is regenerated.
  <br/><sub>`bazel-bin`, `bazel-out`, the output base, `bazel clean`</sub>

**[031 &middot; bazel query Basics](031_query_basics/)** - `bazel query` answers questions about the build graph **without building anything**. It works on the graph as written in BUILD files (the loading-phase graph).
  <br/><sub>`query`, `deps`, `rdeps`, `somepath`</sub>

**[032 &middot; build vs run vs test](032_build_run_test/)** - `build` for artifacts, `run` for tools, `test` for verification. Only `test` caches a *result* rather than just outputs.
  <br/><sub>the three core commands</sub>

**[033 &middot; .bazelrc: Persistent Flags](033_bazelrc_basics/)** - Read the repo's [`.bazelrc`](../../.bazelrc) alongside this file.
  <br/><sub>`.bazelrc`, flag precedence, `try-import`</sub>

**[034 &middot; Named Configurations with --config](034_bazelrc_configs/)** - If you ever type more than two flags together twice, make it a `--config`.
  <br/><sub>`--config`, `build:<name>`, flag bundles</sub>

**[035 &middot; MODULE.bazel and bazel_dep](035_module_basics/)** - `bazel_dep(name, version)` is the whole external-dependency story for anything published to the registry. Samples 066-070 cover the cases that are not.
  <br/><sub>bzlmod, `bazel_dep`, the Bazel Central Registry</sub>

**[036 &middot; Using bazel_skylib](036_using_skylib/)** - Before writing a genrule, check whether skylib already has the rule. It usually does, and its version is the portable one.
  <br/><sub>skylib rules, portability over genrule</sub>

**[037 &middot; $(location) and Friends](037_location_expansion/)** - Never write a literal `bazel-bin/...` path. Let `$(execpath)` compute it.
  <br/><sub>`$(location)`, `$(execpath)`, `$(rootpath)`, `tools`</sub>

**[038 &middot; Make Variables](038_make_variables/)** - Make variables let a command adapt to the configuration without a `select()`. Remember `$$` for literal dollars.
  <br/><sub>`$(VAR)`, predefined variables, `toolchains`</sub>

**[039 &middot; Header-Only Libraries](039_header_only/)** - A target is a node in the dependency graph, not necessarily a compilation step. Header-only libraries carry metadata, and that is reason enough to declare them.
  <br/><sub>`hdrs` without `srcs`, interface targets</sub>

**[040 &middot; A Binary With Runtime Data](040_binary_with_data/)** - `data` + `filegroup` + `glob` is the standard way to attach a directory of runtime assets to a program.
  <br/><sub>`data` + `filegroup`, packaging for runtime</sub>

**[041 &middot; testonly: Keeping Test Code Out of Production](041_testonly/)** - Mark every test helper `testonly = True`. It costs one line and permanently prevents a whole class of accident.
  <br/><sub>`testonly`, dependency hygiene</sub>

**[042 &middot; bazel info and the Directory Layout](042_bazel_info/)** - `bazel info` is how you find anything Bazel produced without guessing at paths.
  <br/><sub>`bazel info`, output base, execution root, the server</sub>

**[043 &middot; Debugging BUILD Files](043_debugging_build_files/)** - BUILD files are code and debug like code. `print()` for values, `fail()` for validation, `query --output=build` for "what did this expand to".
  <br/><sub>`print()`, `fail()`, `--output=build`, loading phase</sub>

**[044 &middot; Target Patterns on the Command Line](044_target_patterns/)** - `...` recurses, `:all` does not, and `manual` opts out of both.
  <br/><sub>`:all`, `...`, exclusion, `--build_tag_filters`</sub>

**[045 &middot; Reading Bazel Error Messages](045_reading_errors/)** - Bazel errors name the **phase** they came from. Identifying the phase tells you where to look.
  <br/><sub>error taxonomy, `--verbose_failures`, `--sandbox_debug`</sub>

**[046 &middot; package_group: Managing Visibility at Scale](046_package_groups/)** - `package_group` turns visibility from per-target boilerplate into a named, reviewable policy.
  <br/><sub>`package_group`, `includes`, allowlists</sub>

**[047 &middot; Chaining Build Steps](047_genrule_pipeline/)** - Declare inputs and outputs; ordering and parallelism follow automatically. This is the core idea that scales from 3 actions to 3 million.
  <br/><sub>implicit ordering, intermediate artifacts, incrementality</sub>

**[048 &middot; Code Generation With a Tool](048_tools_in_genrule/)** - Make your generators Bazel targets. Then "the generator changed" is a real graph edge instead of a stale artifact nobody notices.
  <br/><sub>`tools`, generated sources, tool dependency tracking</sub>

**[049 &middot; The Common Attributes](049_common_attributes/)** - Every rule - `cc_library`, `py_binary`, `java_test`, your own custom rules - accepts this set. Learning them once covers most of what you read in BUILD files.
  <br/><sub>attributes shared by all rules</sub>

**[050 &middot; Capstone: A Complete Small Project](050_capstone_basics/)** - A complete small C++ project: library, binary, unit test, end-to-end test, shared fixtures and a test_suite, assembling 001-049.
  <br/><sub>everything from 001-049 together</sub>


### Composition - reusing and configuring  (051-100)

Macros, `select()`, custom flags, platforms, external dependencies through bzlmod, protobuf shared across languages, and packaging. Where BUILD files stop being repetitive.

`bazel test //:composition`

**[051 &middot; Legacy Macros](051_legacy_macros/)** - Macros remove repetition in BUILD files. They add no build-time cost, because they are gone before the build starts.
  <br/><sub>macros, loading phase, `--output=build`</sub>

**[052 &middot; Symbolic Macros](052_symbolic_macros/)** - Symbolic macros give macros a schema and an encapsulation boundary. They are the default choice in Bazel 8+.
  <br/><sub>`macro()`, attribute schemas, naming rules</sub>

**[053 &middot; Organizing .bzl Files](053_bzl_organization/)** - Treat `.bzl` files like any other library code: layered, with a deliberate public surface marked by the absence of a leading underscore.
  <br/><sub>`load()`, `bzl_library`, public vs private symbols</sub>

**[054 &middot; Starlark Inside BUILD Files](054_starlark_in_build/)** - Comprehensions for repetition, `.bzl` macros for logic, `select()` for configuration.
  <br/><sub>comprehensions, string formatting, load-time `if`</sub>

**[055 &middot; Starlark Data Types](055_starlark_data_types/)** - Prefer `struct` for grouped data, build new values instead of mutating, and remember that everything freezes at the end of loading.
  <br/><sub>`dict`, `struct`, immutability, `depset` preview</sub>

**[056 &middot; select(): Configurable Attributes](056_select_basics/)** - `select()` is how one BUILD file describes many configurations. The branch is chosen at analysis time, so each configuration gets its own cached result.
  <br/><sub>`select()`, `config_setting`, `//conditions:default`</sub>

**[057 &middot; config_setting in Depth](057_config_setting/)** - `config_setting` is a named predicate over the configuration. `select()` is the switch statement that consumes it.
  <br/><sub>`values`, `define_values`, `constraint_values`, specificity</sub>

**[058 &middot; select() Defaults and Errors](058_select_defaults/)** - A missing default is a feature. Use it to make unsupported configurations fail loudly, and always pair it with `no_match_error`.
  <br/><sub>`//conditions:default`, `no_match_error`, fail-fast</sub>

**[059 &middot; Custom Build Settings (string_flag)](059_string_flag/)** - Custom build settings are the modern replacement for `--define`. Use them for anything a user is meant to toggle.
  <br/><sub>`build_setting`, `BuildSettingInfo`, `flag_values`</sub>

**[060 &middot; bool_flag, int_flag and label_flag](060_bool_and_label_flags/)** - `bool_flag` and `string_flag` cover configuration. `label_flag` covers substitution, and it is far more powerful than it first appears.
  <br/><sub>skylib flag rules, `label_flag`, dependency injection</sub>

**[061 &middot; The --define Flag](061_define_flag/)** - Recognize `--define` when you read it; reach for `string_flag` when you write it.
  <br/><sub>`--define`, `define_values`, why it is legacy</sub>

**[062 &middot; Constraints and Platforms](062_constraints/)** - Constraints describe machines declaratively, which lets Bazel *resolve* the right toolchain instead of you hard-coding one.
  <br/><sub>`constraint_setting`, `constraint_value`, `platform`</sub>

**[063 &middot; Declaring and Selecting Platforms](063_platforms/)** - Define platforms once, centrally. Then `--platforms` is the single switch that retargets the entire build.
  <br/><sub>`platform()`, `parents`, `--platforms`</sub>

**[064 &middot; Selecting on the Target Platform](064_select_on_platform/)** - `select()` + `@platforms//os` is the portable-code idiom. Centralize the `config_setting` definitions.
  <br/><sub>`@platforms//os`, selecting `deps` and `data`</sub>

**[065 &middot; alias + select: Swappable Implementations](065_alias_select/)** - `alias` + `select` is Bazel's dependency-injection mechanism. Learn it early; it shows up everywhere.
  <br/><sub>the alias-select dispatch pattern</sub>

**[066 &middot; http_archive: Depending on Non-Bazel Code](066_http_archive/)** - `http_archive` + a hand-written `build_file` is how any C/C++ tarball on the internet becomes a first-class Bazel dependency.
  <br/><sub>`use_repo_rule`, `http_archive`, `build_file`, checksums</sub>

**[067 &middot; Renaming External Repositories](067_repo_renaming/)** - `repo_name` decouples "what the module calls itself" from "what I call it". The mapping is local to your module, which is what makes bzlmod compose.
  <br/><sub>`repo_name`, repository name mapping</sub>

**[068 &middot; local_path_override: Using a Module From Disk](068_local_path_override/)** - `local_path_override` is the standard workflow for developing two modules at once. It is a root-module-only escape hatch, which is exactly right.
  <br/><sub>`local_path_override`, local development workflow</sub>

**[069 &middot; The Override Family](069_overrides/)** - Overrides are root-module-only escape hatches. Reach for `single_version_override` with `patches` before forking a dependency.
  <br/><sub>`single_version_override`, `archive_override`, `git_override`</sub>

**[070 &middot; Module Extensions](070_module_extension/)** - A module extension is the bridge between declarative `MODULE.bazel` data and imperative repository creation. Samples 137-139 go deeper.
  <br/><sub>`module_extension`, `tag_class`, `use_repo`</sub>

**[071 &middot; Inspecting the Module Graph](071_bazel_mod/)** - `bazel mod graph` and `bazel mod explain` replace guesswork about external dependencies with a direct answer.
  <br/><sub>`bazel mod`, lockfiles, dependency debugging</sub>

**[072 &middot; Java Libraries and Binaries](072_java_basics/)** - `java_library` + `java_binary` mirror `cc_library` + `cc_binary` exactly.
  <br/><sub>`java_library`, `java_binary`, `main_class`, hermetic JDK</sub>

**[073 &middot; Java Tests](073_java_test/)** - `java_test` defaults to JUnit; `use_testrunner = False` gives you the plain exit-code contract. Maven dependencies arrive via `rules_jvm_external`.
  <br/><sub>`java_test`, `test_class`, `use_testrunner`</sub>

**[074 &middot; proto_library](074_proto_library/)** - `proto_library` describes the schema; it never generates code. Always declare `deps` to match your `import` statements.
  <br/><sub>`proto_library`, import paths, language neutrality</sub>

**[075 &middot; C++ Protocol Buffers](075_cc_proto/)** - One `proto_library`, one `cc_proto_library`, and the include path is the `.proto` path with a `.pb.h` extension.
  <br/><sub>`cc_proto_library`, generated headers, transitivity</sub>

**[076 &middot; One Schema, Multiple Languages](076_multi_language_proto/)** - Declare the schema once with `proto_library`, then add one wrapper per language that needs it. The wrappers cost nothing when nobody depends on them.
  <br/><sub>`java_proto_library`, polyglot schema sharing</sub>

**[077 &middot; Test Sharding](077_test_sharding/)** - `shard_count` is a one-line change that turns a slow suite into a parallel one - provided the test runner cooperates.
  <br/><sub>`shard_count`, `TEST_SHARD_INDEX`, parallelism</sub>

**[078 &middot; Flaky Tests](078_flaky_tests/)** - `--runs_per_test` to find flakiness, `flaky = True` to quarantine briefly, and a real fix to close it out.
  <br/><sub>`flaky`, `--runs_per_test`, `--flaky_test_attempts`</sub>

**[079 &middot; Code Coverage](079_coverage/)** - `bazel coverage` works out of the box. Set `--instrumentation_filter` or the numbers will be meaningless.
  <br/><sub>`bazel coverage`, LCOV, `--combined_report`</sub>

**[080 &middot; The C++ Runfiles Library](080_cc_runfiles/)** - Any program that reads `data` files and might be run outside `bazel run` should use the runfiles library.
  <br/><sub>`Rlocation`, robust data access</sub>

**[081 &middot; The Python Runfiles Library](081_py_runfiles/)** - `runfiles.Create()` + `Rlocation()` is three lines and makes data access portable. Use it in anything beyond a throwaway script.
  <br/><sub>`python.runfiles`, `Rlocation`, tests vs binaries</sub>

**[082 &middot; run_binary: Invoking a Tool Without a Shell](082_run_binary/)** - Reach for `run_binary` when the job is "run this program with these arguments". Keep `genrule` for genuine shell work.
  <br/><sub>`run_binary`, genrule alternatives, portability</sub>

**[083 &middot; expand_template: Generating Files From Templates](083_expand_template/)** - `expand_template` is the portable way to turn a template plus values into a generated source file. Use unmistakable placeholder syntax.
  <br/><sub>`expand_template`, generated headers, substitution</sub>

**[084 &middot; Multiple Outputs From One Action](084_multiple_outputs/)** - Multiple outputs are fine and often desirable - one action producing five files is cheaper than five actions. Just name each output explicitly in `cmd`.
  <br/><sub>multiple `outs`, `$(location)`, output selection</sub>

**[085 &middot; Packaging With pkg_tar](085_pkg_tar/)** - `pkg_tar` turns build outputs into a distributable artifact. Remember `include_runfiles = True` for anything executable.
  <br/><sub>`pkg_tar`, `package_dir`, `strip_prefix`, `deps`</sub>

**[086 &middot; Fine-Grained Packaging With pkg_files](086_pkg_files/)** - `pkg_files` separates *what goes where with which permissions* from *what archive format*. Define the layout once, emit any number of package types.
  <br/><sub>`pkg_files`, `pkg_attributes`, `pkg_mkdirs`, `strip_prefix`</sub>

**[087 &middot; Golden File Testing With diff_test](087_diff_test/)** - `diff_test` is a complete assertion framework for "the output should look exactly like this", and it pairs with `write_source_files` for painless updates.
  <br/><sub>`diff_test`, golden files, characterization tests</sub>

**[088 &middot; build_test: Making "It Compiles" a Test](088_build_test/)** - If a target matters but nothing depends on it, wrap it in a `build_test` or CI will silently stop checking it.
  <br/><sub>`build_test`, CI coverage of non-test targets</sub>

**[089 &middot; Combining Conditions With config_setting_group](089_config_setting_group/)** - `match_any` = OR, `match_all` = AND. Name your combinations rather than duplicating conditions.
  <br/><sub>`selects.config_setting_group`, AND / OR logic</sub>

**[090 &middot; The skylib Helper Libraries](090_skylib_helpers/)** - skylib's helpers are small, correct and already a dependency of your build. Reach for them instead of re-implementing string manipulation - especially `shell.quote`.
  <br/><sub>`paths`, `shell`, `dicts`, `collections`, `versions`</sub>

**[091 &middot; Workspace Status and Stamping](091_workspace_status/)** - `STABLE_` means "part of the cache key". Use it only for values that genuinely identify the source state.
  <br/><sub>`--stamp`, `--workspace_status_command`, `info_file` vs `version_file`</sub>

**[092 &middot; Stamping a Release Artifact](092_stamped_release/)** - Stamping connects a deployed artifact to the source that produced it. Structure it so that connection costs you almost nothing in build time.
  <br/><sub>traceable builds, stamped manifests, `--config=release`</sub>

**[093 &middot; Query Operators in Depth](093_query_operators/)** - The query operators worth memorizing - deps, rdeps, somepath, kind, filter, set operations - and when to reach for cquery instead.
  <br/><sub>query operators, `cquery` vs `query`, impact analysis</sub>

**[094 &middot; Query Output Formats and genquery](094_query_output/)** - `--output` formats make query scriptable; `genquery` makes query results part of the build graph.
  <br/><sub>`--output`, Graphviz, `genquery`</sub>

**[095 &middot; Formatting and Linting With buildifier](095_buildifier/)** - Format automatically and enforce it in CI. Sorted, canonical BUILD files remove an entire category of review comments and merge conflicts.
  <br/><sub>`buildifier`, `buildozer`, CI formatting gates</sub>

**[096 &middot; The `native` Module](096_native_in_macros/)** - `native.` for built-in rules inside `.bzl` files; `load()` for everything else. Avoid `existing_rule` unless you have no alternative.
  <br/><sub>`native.*`, package context, macro helpers</sub>

**[097 &middot; Generating a Test Matrix](097_test_matrix/)** - Generate one target per combination. You get parallelism, caching, and precise failure attribution for the cost of a nested loop.
  <br/><sub>macro-generated targets, parameterized tests, tag filtering</sub>

**[098 &middot; A Multi-Language Application](098_multi_language/)** - Bazel's value grows with the number of languages in the repo. The schema is a build target, so the compiler enforces the contract across language boundaries.
  <br/><sub>polyglot builds, shared schema, cross-language testing</sub>

**[099 &middot; A Complete Release Pipeline](099_release_pipeline/)** - Put packaging *in* the build graph. A release becomes a reproducible, incremental, verifiable target rather than a shell script nobody trusts.
  <br/><sub>build → metadata → layout → package → verify</sub>

**[100 &middot; Capstone: Composable Build](100_capstone_composition/)** - A proto-backed task app whose storage backend is picked by a build flag, baked into a generated source file at analysis time, then packaged.
  <br/><sub>everything from 051-099 together</sub>


### Authoring - writing your own rules  (101-150)

Actions, providers, depsets, output groups, toolchains, aspects, transitions and persistent workers. This is the part that took me longest, so the examples here are the most detailed.

`bazel test //:authoring`

**[101 &middot; Your First Custom Rule](101_simple_rule/)** - A rule implementation is a pure function from attributes to a description of actions. Nothing executes until Bazel decides it must.
  <br/><sub>`rule()`, implementation functions, analysis phase</sub>

**[102 &middot; Rule Attributes](102_rule_attributes/)** - Attributes are the rule's public API. Choose the types carefully; label attributes are dependency edges, not just strings.
  <br/><sub>attribute declaration, `ctx.attr` vs `ctx.file(s)`</sub>

**[103 &middot; Attribute Types and Validation](103_attr_types/)** - Validate as early and as declaratively as you can. Every constraint you encode is an error message someone does not have to debug.
  <br/><sub>`values`, `mandatory`, `providers`, `fail()`</sub>

**[104 &middot; ctx.actions.write](104_actions_write/)** - `ctx.actions.write` is the cheapest way to produce a file. Prefer it over a genrule whenever the content is computable in Starlark.
  <br/><sub>`declare_file`, `write`, `short_path` vs `path`</sub>

**[105 &middot; ctx.actions.run](105_actions_run/)** - `ctx.actions.run` executes a declared tool with declared inputs and outputs. `cfg = "exec"` on the tool attribute is not optional.
  <br/><sub>`run`, `Args`, `cfg = "exec"`, mnemonics</sub>

**[106 &middot; ctx.actions.run_shell](106_actions_run_shell/)** - `run_shell` is for shell features, not for convenience. Start with `set -euo pipefail`, pass values as arguments, and migrate complex logic into a proper tool.
  <br/><sub>`run_shell`, shell pipelines, when not to use it</sub>

**[107 &middot; ctx.actions.expand_template](107_actions_expand_template/)** - Use the skylib rule for static substitutions in BUILD files; use `ctx.actions.expand_template` when the values must be computed during analysis.
  <br/><sub>templating in rules, computed substitutions</sub>

**[108 &middot; declare_directory and Tree Artifacts](108_declare_directory/)** - Tree artifacts trade caching granularity for the ability to model tools whose output set is dynamic. Use them deliberately, not by default.
  <br/><sub>tree artifacts, unpredictable outputs</sub>

**[109 &middot; Predeclared Outputs](109_predeclared_outputs/)** - `declare_file` for internal outputs; `attr.output` or the `outputs` dict when the filename is part of the contract.
  <br/><sub>`attr.output`, the `outputs` dict, addressable files</sub>

**[110 &middot; DefaultInfo](110_default_info/)** - `DefaultInfo.files` is the build output; `DefaultInfo.runfiles` is the runtime closure. Deciding what belongs in each is a real design decision, not a formality.
  <br/><sub>`files`, `runfiles`, `executable`, default outputs</sub>

**[111 &middot; Runfiles in Custom Rules](111_runfiles_in_rules/)** - Runfiles are the runtime closure and they must be assembled explicitly. `merge_all` plus `short_path` are the two things to get right.
  <br/><sub>`ctx.runfiles`, merging, `short_path`</sub>

**[112 &middot; Executable Rules](112_executable_rules/)** - `executable = True` plus `DefaultInfo(executable = ...)`. Executable rules are how operational scripts join the build graph.
  <br/><sub>`executable = True`, `bazel run`, custom tooling</sub>

**[113 &middot; Custom Test Rules](113_custom_test_rules/)** - `test = True` is the whole difference. Custom test rules are the natural home for repo-wide policy checks.
  <br/><sub>`test = True`, test environment, policy tests</sub>

**[114 &middot; Custom Providers](114_custom_providers/)** - Providers are the API boundary between rules. Declare `fields` with documentation, and require them with `attr.label(providers = [...])`.
  <br/><sub>`provider()`, typed data between rules</sub>

**[115 &middot; Designing Providers](115_provider_design/)** - Use an `init` callback for validation and derived fields. Document every field, prefer `depset` for transitive data, and keep the raw constructor private.
  <br/><sub>`init` callbacks, derived fields, API evolution</sub>

**[116 &middot; depset: Transitive Data Without Quadratic Cost](116_depset_basics/)** - `depset(direct = ..., transitive = [...])` is the single most important performance idiom in Starlark. Reach for `to_list()` reluctantly.
  <br/><sub>`depset`, `to_list()`, deduplication</sub>

**[117 &middot; depset Traversal Order](117_depset_order/)** - Pick `default` by default. Use `postorder`/`preorder` only when producing an order-sensitive command line, and keep the choice consistent across the rule set.
  <br/><sub>`postorder`, `preorder`, `topological`, link order</sub>

**[118 &middot; The Transitive Collection Pattern](118_transitive_pattern/)** - Collect with `depset(direct=, transitive=)` in every library, flatten once in the binary, and pass depsets to actions rather than lists.
  <br/><sub>a complete miniature rule set</sub>

**[119 &middot; OutputGroupInfo](119_output_groups/)** - Keep `DefaultInfo.files` minimal and put everything optional in an output group. It costs nothing when unused.
  <br/><sub>`OutputGroupInfo`, optional outputs, `output_group`</sub>

**[120 &middot; Validation Actions](120_validation_actions/)** - `OutputGroupInfo(_validation = ...)` gives you checks that run on every build, in parallel with real work, without becoming a dependency.
  <br/><sub>the `_validation` output group, non-blocking checks</sub>

**[121 &middot; Implicit Dependencies](121_implicit_deps/)** - Private `_`-prefixed label attributes are how rules carry their own tooling. Always wrap the default in `Label()`.
  <br/><sub>private attributes, `_` prefix, hidden tools</sub>

**[122 &middot; Exec vs Target Configuration](122_exec_vs_target/)** - `cfg = "exec"` on every tool attribute. It is invisible on a local build and mandatory for cross-compilation and remote execution.
  <br/><sub>`cfg = "exec"`, `cfg = "target"`, cross-compilation</sub>

**[123 &middot; Toolchains: The Basics](123_toolchain_basics/)** - A toolchain type is an interface; toolchains are implementations; platforms and constraints select between them. Rules depend on the interface only.
  <br/><sub>`toolchain_type`, `toolchain()`, `ctx.toolchains`</sub>

**[124 &middot; A Toolchain That Carries a Tool](124_custom_toolchain/)** - Put the tool *and* its `files_to_run` in the `ToolchainInfo`, and pass the latter to `tools`. Consumers then never name a specific implementation.
  <br/><sub>`files_to_run`, tools in toolchains</sub>

**[125 &middot; Registering Toolchains](125_toolchain_registration/)** - `register_toolchains()` in `MODULE.bazel` makes toolchains available repo-wide. First compatible match wins, so order expresses preference.
  <br/><sub>`register_toolchains`, resolution order</sub>

**[126 &middot; Debugging Toolchain Resolution](126_toolchain_debugging/)** - `--toolchain_resolution_debug` with a narrow regex answers almost every toolchain question. Most failures are registration order, constraints, or visibility.
  <br/><sub>`--toolchain_resolution_debug`, common failures</sub>

**[127 &middot; Exec Groups](127_exec_groups/)** - Exec groups partition a rule's actions so each subset can get its own platform, toolchains and execution properties.
  <br/><sub>`exec_group`, per-action execution requirements</sub>

**[128 &middot; target_compatible_with: Platform-Incompatible Targets](128_target_compatible_with/)** - `target_compatible_with` lets one `bazel test //...` be correct on every platform. It is the right answer to "this test only works on Linux".
  <br/><sub>`target_compatible_with`, graceful skipping</sub>

**[129 &middot; Cross-Compilation](129_cross_compilation/)** - Cross-compilation is toolchain resolution driven by `--platforms`. Rules stay architecture-agnostic; toolchains carry the differences.
  <br/><sub>`--platforms`, target-constrained toolchains</sub>

**[130 &middot; Aspects: The Basics](130_aspect_basics/)** - An aspect adds analysis to a graph you do not own. `(target, ctx)`, `ctx.rule.attr` for the visited rule, and defensive `hasattr` checks.
  <br/><sub>`aspect()`, `attr_aspects`, `ctx.rule`</sub>

**[131 &middot; Aspect Propagation](131_aspect_propagation/)** - `attr_aspects` is the traversal specification. Keep it narrow, give aspects private attributes with defaults, and type-check when iterating generically.
  <br/><sub>`attr_aspects`, aspect attributes, traversal control</sub>

**[132 &middot; Applying an Aspect From a Rule](132_aspect_from_rule/)** - `attr.label_list(aspects = [...])` turns an aspect into an ordinary build target. Prefer it for anything the team depends on.
  <br/><sub>`attr.label_list(aspects = [...])`, productionizing aspects</sub>

**[133 &middot; Aggregating Output Groups in an Aspect](133_aspect_output_groups/)** - Return the aggregated depset in both a provider and `OutputGroupInfo` at every level. That is what makes a single top-level request collect the whole graph.
  <br/><sub>transitive output groups, aspect-driven codegen</sub>

**[134 &middot; A Linting Aspect](134_aspect_linting/)** - An aspect turns linting into cached, parallel, incremental build actions. Combine with the `_validation` output group to enforce it everywhere.
  <br/><sub>aspect + tool, incremental linting, report aggregation</sub>

**[135 &middot; Repository Rules](135_repository_rules/)** - Repository rules run early, unsandboxed, and cached. Declare every environment dependency with `environ` and `getenv`, or you have built a non-reproducible build.
  <br/><sub>`repository_rule`, `repository_ctx`, loading phase</sub>

**[136 &middot; Repository Rules That Execute and Download](136_repository_rule_execute/)** - `execute` + `file` is how you turn anything - a system tool, a package manager, a code generator - into a Bazel repository.
  <br/><sub>`execute`, `download`, `which`, generated BUILD files</sub>

**[137 &middot; Module Extensions in Depth](137_module_extension_depth/)** - An extension's power is the global view of every module's requests. Use it to resolve conflicts centrally, and describe the result honestly with `extension_metadata`.
  <br/><sub>`module_ctx.modules`, aggregation, `extension_metadata`</sub>

**[138 &middot; Designing Tag Classes](138_tag_classes/)** - Sample 137 has a working extension; this one is about the **shape** of the API you expose through it.
  <br/><sub>`tag_class`, extension API design</sub>

**[139 &middot; The Lockfile and Reproducibility](139_lockfile/)** - Commit the lockfile, enforce it in CI with `--lockfile_mode=error`, regenerate on conflict, and be honest about `reproducible`.
  <br/><sub>`MODULE.bazel.lock`, `--lockfile_mode`, `bazel mod tidy`</sub>

**[140 &middot; Reading Build Settings in a Rule](140_build_settings_in_rules/)** - `attr.label` pointing at the flag, plus `BuildSettingInfo`, lets a rule compute from a flag rather than merely switching on it.
  <br/><sub>`BuildSettingInfo`, `ctx.var`, flag-driven rules</sub>

**[141 &middot; Incoming Edge Transitions](141_incoming_transitions/)** - `cfg = <transition>` on a rule pins the configuration for that target and its subgraph.
  <br/><sub>`transition()`, `cfg` on a rule, self-configuring targets</sub>

**[142 &middot; Outgoing and Split Transitions](142_outgoing_transitions/)** - `cfg` on an attribute changes the dependency's configuration; returning a dict of dicts builds it several ways, read back through `ctx.split_attr`.
  <br/><sub>`cfg` on an attribute, split transitions, `ctx.split_attr`</sub>

**[143 &middot; Inspecting Configurations](143_configuration_inspection/)** - `bazel config` and `cquery` are how you see the configured graph. Two cquery lines for one label means two configurations - find out why.
  <br/><sub>`bazel config`, `cquery`, configuration hashes</sub>

**[144 &middot; Custom Make Variables](144_template_variables/)** - `TemplateVariableInfo` plus `toolchains = [...]` gives you scoped, defaulted, discoverable Make variables - everything `--define` lacks.
  <br/><sub>`TemplateVariableInfo`, the `toolchains` attribute</sub>

**[145 &middot; The Args API](145_args_api/)** - Use `Args` for every non-trivial command line. It is lazy, it handles depsets and tree artifacts, and it enables param files for free.
  <br/><sub>`ctx.actions.args()`, lazy expansion, `map_each`</sub>

**[146 &middot; Parameter Files](146_param_files/)** - Any rule whose argument count scales with the number of inputs needs `use_param_file`. Make your tools accept `@file`, and prefer the `multiline` format.
  <br/><sub>`use_param_file`, ARG_MAX, long command lines</sub>

**[147 &middot; Persistent Workers](147_persistent_workers/)** - Workers amortize startup cost across actions. Declare `supports-workers`, pass arguments in a param file, support standalone mode, and keep the process stateless.
  <br/><sub>worker protocol, `supports-workers`, warm processes</sub>

**[148 &middot; Debugging Actions](148_action_debugging/)** - `--subcommands` for what ran, `--sandbox_debug` for missing inputs, `--explain` for unexpected rebuilds, `--execution_log_json_file` for reproducibility.
  <br/><sub>`--subcommands`, `--sandbox_debug`, `--execution_log`</sub>

**[149 &middot; aquery: Inspecting the Action Graph](149_aquery/)** - `aquery` is the ground truth for "what command will Bazel run". Use it whenever a flag, input, or environment variable is not doing what you expect.
  <br/><sub>`aquery`, action inspection, build analysis</sub>

**[150 &middot; Capstone: A Complete Rule Set](150_capstone_rule_set/)** - A full miniature rule set: providers, depsets, a toolchain, an executable rule, a custom test rule, output groups and a lint aspect.
  <br/><sub>everything from 101-149 assembled</sub>


### Operations - running it at scale  (151-200)

Caching, remote execution, hermeticity, reproducibility, profiling, testing Starlark itself, CI design and release engineering. Mostly the things that only start to matter once the repo is big.

`bazel test //:operations`

**[151 &middot; The Disk Cache](151_disk_cache/)** - `--disk_cache` is one line for a large win on any machine where you clean, switch branches, or keep several checkouts.
  <br/><sub>`--disk_cache`, action cache vs disk cache</sub>

**[152 &middot; The Repository Cache and Vendoring](152_repository_cache/)** - The repository cache is shared and content-addressed - always set `sha256`. `bazel vendor` gives a genuinely offline build when policy requires it.
  <br/><sub>repository cache, `bazel vendor`, offline builds</sub>

**[153 &middot; Remote Caching](153_remote_cache/)** - Remote caching turns CI's work into everyone's speedup. It only works if your builds are hermetic - which is what makes sample 160 worth reading before you turn it on.
  <br/><sub>`--remote_cache`, cache keys, CI/developer sharing</sub>

**[154 &middot; Remote Execution](154_remote_execution/)** - Remote execution buys parallelism far beyond your machine, and demands hermeticity in return. Fix hermeticity first; the rest is configuration.
  <br/><sub>`--remote_executor`, execution platforms, containers</sub>

**[155 &middot; Build Without the Bytes](155_build_without_bytes/)** - With any remote setup, set a download policy. `minimal` for CI, `toplevel` for developers - otherwise you pay to download artifacts nobody reads.
  <br/><sub>`--remote_download_*`, output materialization</sub>

**[156 &middot; The Build Event Protocol](156_build_event_protocol/)** - Do not parse Bazel's console output. Emit the BEP, query it with `jq`, and graph `buildMetrics` over time.
  <br/><sub>BEP, `--build_event_json_file`, build observability</sub>

**[157 &middot; Profiling a Build](157_profiling/)** - Profile before optimizing. The phase breakdown says which of three unrelated problems you actually have, and the critical path bounds what is achievable.
  <br/><sub>`--profile`, `analyze-profile`, critical path</sub>

**[158 &middot; Sandboxing](158_sandboxing/)** - The sandbox is what makes undeclared inputs fail fast. Do not switch it off to make a build pass - fix the declaration.
  <br/><sub>sandbox strategies, undeclared inputs, `--sandbox_debug`</sub>

**[159 &middot; Execution Strategies](159_spawn_strategies/)** - Strategies are chosen per mnemonic. Start with the defaults, measure with the execution log, and only then pin specific mnemonics.
  <br/><sub>`--spawn_strategy`, `--strategy`, dynamic execution</sub>

**[160 &middot; Hermeticity: The Checklist](160_hermeticity/)** - A build is **hermetic** when the same inputs produce the same outputs on any machine, at any time.
  <br/><sub>reproducibility, the prerequisites for caching</sub>

**[161 &middot; The Action Environment](161_action_environment/)** - Every environment variable you let in becomes part of the cache key. Pass fixed values, never host-dependent ones.
  <br/><sub>`--action_env`, `--host_action_env`, cache keys</sub>

**[162 &middot; The Execution Log](162_execution_log/)** - The execution log is the ground truth for reproducibility and cache-miss debugging. Diff two logs before theorizing about either.
  <br/><sub>`--execution_log_json_file`, diffing builds</sub>

**[163 &middot; Verifying Reproducible Builds](163_reproducible_builds/)** - Reproducibility is verifiable, not aspirational. Diff hashes across output bases and machines; diff execution logs when they disagree.
  <br/><sub>bit-for-bit reproducibility, verification techniques</sub>

**[164 &middot; Dependency Update Workflow](164_dependency_updates/)** - MVS makes upgrades explicit. Commit `MODULE.bazel` and the lockfile together, enforce it in CI, and patch rather than fork.
  <br/><sub>MVS in practice, upgrade hygiene, CI gates</sub>

**[165 &middot; Repository Layout and Bazel Upgrades](165_monorepo_layout/)** - Pin `.bazelversion`, centralize `config_setting`s, keep build infrastructure in its own tree, and upgrade Bazel through incompatible flags rather than in one jump.
  <br/><sub>monorepo structure, `.bazelversion`, incompatible flags</sub>

**[166 &middot; Multi-Module Repositories](166_multi_module/)** - Sample 068 has a working nested module at `068_local_path_override/greeting_lib`. This sample is about when and why you would structure a repo that way.
  <br/><sub>nested modules, `local_path_override`, splitting a repo</sub>

**[167 &middot; layering_check: Strict Deps for C++](167_layering_check/)** - `--features=layering_check` gives C++ the strict-deps guarantee Java has by default. Turn it on if your toolchain is Clang.
  <br/><sub>`layering_check`, `parse_headers`, transitive includes</sub>

**[168 &middot; Writing a C++ Toolchain](168_cc_toolchain_config/)** - `cc_toolchain_config` describes tool paths plus features. Reach for an existing toolchain module first; write your own only for genuinely bespoke hardware.
  <br/><sub>`cc_toolchain`, `cc_common.create_cc_toolchain_config_info`, features</sub>

**[169 &middot; Hermetic Toolchains](169_hermetic_toolchain/)** - Pin the compiler like any other dependency. It is the single highest-impact change for remote cache hit rates and cross-machine consistency.
  <br/><sub>removing the host compiler from the build</sub>

**[170 &middot; Multi-Platform Build Matrices](170_platform_matrix/)** - `--platforms` is the one switch that retargets a build. Run it as a CI matrix and share a remote cache across the jobs.
  <br/><sub>`--platforms` in CI, per-platform artifacts</sub>

**[171 &middot; Container Images](171_container_images/)** - Build layers with `pkg_tar`, assemble with `oci_image`, pin the base by digest, and order layers by change frequency.
  <br/><sub>`rules_oci`, layering, reproducible images</sub>

**[172 &middot; Operating System Packages](172_os_packages/)** - `pkg_files` defines the layout once; `pkg_deb`/`pkg_rpm`/`pkg_tar`/`oci_image` consume it. Test the artifact, and drive the version from the build.
  <br/><sub>`pkg_deb`, `pkg_rpm`, install layouts</sub>

**[173 &middot; Release Artifacts and Provenance](173_release_provenance/)** - Provenance is derivable from the build graph. Stamp the commit, emit the dependency list as an artifact, and archive the BEP.
  <br/><sub>stamping, SBOMs, supply-chain metadata</sub>

**[174 &middot; cquery in Depth](174_cquery_depth/)** - Use `cquery` whenever `select()`, transitions, or output paths are involved. Use `query` when you want speed and only care about what the BUILD files say.
  <br/><sub>configured queries, `select()` resolution</sub>

**[175 &middot; cquery with Starlark Output](175_cquery_starlark/)** - `--output=starlark` turns `cquery` into a programmable interface to the configured build graph. Use it instead of parsing text.
  <br/><sub>`--output=starlark`, programmatic build queries</sub>

**[176 &middot; Build Metrics and Health](176_build_metrics/)** - Track the cache hit rate over time. It is the leading indicator for every Bazel performance problem you are going to have.
  <br/><sub>cache hit rate, trend tracking, `buildMetrics`</sub>

**[177 &middot; Enforcing Dependency Policy](177_dependency_policy/)** - `genquery` + a test turns an architectural rule into a CI gate that fails the moment someone violates it, rather than at review time.
  <br/><sub>`genquery` + tests, architectural rules as CI gates</sub>

**[178 &middot; Test Result Caching](178_test_caching/)** - Test caching is why `bazel test //...` scales. If a cached result looks wrong, suspect an undeclared input before disabling the cache.
  <br/><sub>cached test results, `--cache_test_results`, `external`</sub>

**[179 &middot; Splitting Tests Across CI](179_ci_sharding/)** - Start with `bazel test //...` and caching. Add tag filters when presubmit gets slow. Keep the membership in BUILD files, never in CI YAML.
  <br/><sub>tag filters, `test_suite`, sharding strategies</sub>

**[180 &middot; Coverage at Scale](180_coverage_at_scale/)** - Set `--instrumentation_filter` repo-wide, combine reports, and run coverage postsubmit rather than on every presubmit.
  <br/><sub>`--combined_report`, instrumentation filters, CI integration</sub>

**[181 &middot; Managing Flaky Tests at Scale](181_flaky_management/)** - Detect nightly with `--runs_per_test --nocache_test_results`, quarantine with an owner and a date, and fix the cause. `flaky = True` is a bookmark, not a resolution.
  <br/><sub>detection, quarantine, root-causing</sub>

**[182 &middot; Designing a CI Pipeline](182_ci_pipeline/)** - Encode the pipeline in `.bazelrc` configs, give CI exclusive cache-write access, use tag filters rather than target lists, and track the BEP.
  <br/><sub>presubmit/postsubmit, caching, configs</sub>

**[183 &middot; Target Impact Analysis](183_impact_analysis/)** - Impact analysis must hash the whole input closure, not diff source files. Try a remote cache first - it may make the problem disappear.
  <br/><sub>affected targets, `bazel-diff`, selective CI</sub>

**[184 &middot; Operating a Remote Cache](184_remote_cache_ci/)** - CI writes, developers read, fall back locally on failure, and diagnose low hit rates with an execution-log diff rather than by guessing.
  <br/><sub>deployment, access control, diagnosing misses</sub>

**[185 &middot; Unit Testing Starlark](185_starlark_unit_tests/)** - `unittest.bzl` makes Starlark helpers testable in the loading phase. If a `.bzl` function has a branch, it deserves a test.
  <br/><sub>`unittest.bzl`, `asserts`, testing build logic</sub>

**[186 &middot; Analysis Tests](186_analysis_tests/)** - `analysistest` verifies providers, outputs, actions and failure messages without executing anything. A rule set without analysis tests breaks silently.
  <br/><sub>`analysistest`, testing rule implementations</sub>

**[187 &middot; Testing a Rule Set End to End](187_testing_rule_sets/)** - `build_test` for analysis, `analysistest` for wiring, `diff_test` for output. Stage 2 is the cheapest place to catch the most bugs.
  <br/><sub>the three stages of rule testing</sub>

**[188 &middot; Rule Testing Practices](188_rule_testing_practices/)** - Samples 185-187 showed the mechanics. This one is about judgement.
  <br/><sub>what to test, how to structure it, what to skip</sub>

**[189 &middot; Profiling Starlark](189_starlark_profiling/)** - Profile the phase first, then the Starlark. `to_list()` in a loop and list concatenation for transitive data cause most Starlark slowness.
  <br/><sub>`--starlark_cpu_profile`, slow macros and rules</sub>

**[190 &middot; depset Performance](190_depset_performance/)** - Depsets are not an optimization to apply later - using a list for transitive data is a correctness-of-scale bug that only appears once the graph is large.
  <br/><sub>the O(n²) trap, measuring it, fixing it</sub>

**[191 &middot; Memory and JVM Tuning](191_memory_tuning/)** - Raise `-Xmx` first, then look for configuration multiplication. Avoid `bazel shutdown`, and turn off incremental state in CI.
  <br/><sub>`--host_jvm_args`, the analysis cache, OOM recovery</sub>

**[192 &middot; Loading Phase Performance](192_loading_performance/)** - Narrow your globs, use `.bazelignore` aggressively, and measure with `bazel query //...` before optimizing anything else.
  <br/><sub>glob cost, package granularity, `.bazelignore`</sub>

**[193 &middot; Analysis Phase Optimization](193_analysis_optimization/)** - Analysis cost scales with configured targets. Compare `query` and `cquery` counts; if they diverge, hunt the transition.
  <br/><sub>configured targets, configuration explosion</sub>

**[194 &middot; Symbolic Macro Finalizers](194_macro_finalizers/)** - `finalizer = True` is the only sanctioned way to reason about a whole package.
  <br/><sub>`finalizer = True`, `native.existing_rules()`</sub>

**[195 &middot; Rule Set API Stability](195_api_stability/)** - Providers and attribute defaults are API. Route everything through one public `defs.bzl`, use `deprecation` warnings, and pin the interface with tests.
  <br/><sub>what is public, deprecation, versioning</sub>

**[196 &middot; Publishing a Module](196_publishing_bcr/)** - Publishing means a stable API, a `compatibility_level` you maintain honestly, dev dependencies marked as such, and examples that CI actually builds.
  <br/><sub>the Bazel Central Registry, release hygiene</sub>

**[197 &middot; Rule Composition Patterns](197_rule_composition/)** - Macro for convention, rule for actions, aspect for other people's targets. Compose on providers, not on rule kinds.
  <br/><sub>macros vs rules vs aspects, choosing the right tool</sub>

**[198 &middot; Wrapping Existing Rules](198_wrapping_rules/)** - Same-name wrappers apply repo-wide policy with a one-line change per BUILD file.
  <br/><sub>same-name wrappers, project-wide policy</sub>

**[199 &middot; Migrating From WORKSPACE to bzlmod](199_workspace_migration/)** - `bazel_dep` replaces `http_archive` plus the whole `deps()` chain. The migration work is repository renames and adding `load()` statements - both largely automatable.
  <br/><sub>the migration path, common conversions</sub>

**[200 &middot; Capstone: A Production Pipeline](200_capstone_production/)** - A production pipeline: shared proto schema, a custom config rule behind a toolchain, three kinds of test, stamped provenance, verified release.
  <br/><sub>everything in this repo, assembled into one system</sub>


### Container images - OCI from first principles  (201-250)

What a container image actually is: content-addressed blobs and a JSON index. Built by hand with tar and sha256, no daemon and no registry anywhere.

`bazel test //:images`

**[201 &middot; An OCI Image From First Principles](201_oci_layout_basics/)** - A container image is not a magic format. It is a directory of content-addressed blobs plus a JSON index.
  <br/><sub>OCI image layout, content addressing, manifests, no daemon</sub>

**[202 &middot; Deterministic Layers](202_deterministic_layers/)** - A layer's digest is the hash of its tarball bytes. Anything that varies between builds - timestamps, file order, uid/gid
  <br/><sub>reproducible tarballs, mtime, ordering, ownership</sub>

**[203 &middot; Layer Ordering and Caching](203_layer_caching/)** - Layer order is a caching decision. Least-frequently-changed first.
  <br/><sub>layer granularity, change frequency, push cost</sub>

**[204 &middot; The Image Config Blob](204_image_config/)** - The config blob answers "how do I run this?" and "what filesystem is this?". `diff_ids` are uncompressed hashes; manifest digests are stored-blob hashes.
  <br/><sub>image config JSON, entrypoint vs cmd, rootfs diff_ids</sub>

**[205 &middot; Multi-Architecture Image Index](205_multiarch_index/)** - An index is a platform-keyed list of manifest digests. It is what makes a single image reference work on every architecture.
  <br/><sub>image index, per-platform manifests, one tag many images</sub>

**[206 &middot; Image Annotations](206_image_annotations/)** - Use the standard `org.opencontainers.image.*` keys, keep `created` deterministic, and remember annotations sit outside the signed digest.
  <br/><sub>standard OCI annotations, provenance metadata, digest stability</sub>

**[207 &middot; Pinning the Image Digest](207_reproducible_digest/)** - A pinned digest is the cheapest possible reproducibility regression test.
  <br/><sub>reproducibility as a test, golden digests</sub>

**[208 &middot; An Image Containing One Binary](208_image_from_cc/)** - Static binary plus one layer is the smallest, most secure image you can build, and Bazel already knows the exact runtime closure.
  <br/><sub>static linking, scratch images, runtime closure</sub>

**[209 &middot; Non-Root Images](209_nonroot_image/)** - Ownership goes in the layer, `User` goes in the config, and the uid should be numeric.
  <br/><sub>uid/gid in layers, `User` in the config, least privilege</sub>

**[210 &middot; Enforcing an Image Size Budget](210_image_size_budget/)** - Budget tests turn gradual bloat into an immediate, attributable failure.
  <br/><sub>size regression tests, bloat detection</sub>

**[211 &middot; Image Security Policy as a Test](211_image_policy/)** - An image is just a tarball and some JSON. Policy checks are file inspection, and they belong in the build rather than in a post-publish scan.
  <br/><sub>policy gates, secret scanning, setuid and world-writable checks</sub>

**[212 &middot; One Image Definition, Many Architectures](212_multiarch_transition/)** - A split transition turns "build this for every platform" into data. Read the results back through `ctx.split_attr`.
  <br/><sub>split transitions, `ctx.split_attr`, `target_platform_has_constraint`</sub>

**[213 &middot; Stamping Provenance Into an Image](213_stamped_image/)** - Stamp the commit into annotations via `ctx.info_file`; never stamp a timestamp.
  <br/><sub>`ctx.info_file`, STABLE_ keys, commit not clock</sub>

**[214 &middot; Sharing a Base Layer](214_shared_base_layers/)** - Deduplication is automatic and free - provided your layers are deterministic.
  <br/><sub>content-addressed dedup, registry storage, pull cost</sub>

**[215 &middot; Validating an Image Layout](215_layout_validator/)** - An image layout is checkable without any container tooling. Verify digests, not just structure.
  <br/><sub>spec conformance, digest verification, orphan blobs</sub>

**[216 &middot; Compressed Layers: digest vs diff_id](216_compressed_layers/)** - digest = compressed blob, diff_id = uncompressed tar. They are equal only when you skip compression.
  <br/><sub>`diff_id`, gzip layers, media types</sub>

**[217 &middot; OCI Artifacts: Registries Store More Than Images](217_oci_artifacts/)** - An artifact is a manifest with `artifactType` and an empty config. Registries are artifact stores that happen to be good at images.
  <br/><sub>`artifactType`, empty config, non-image payloads</sub>

**[218 &middot; Referrers: Attaching Signatures and SBOMs to an Image](218_referrers/)** - `subject` links an artifact to an image digest without modifying the image. It is what makes signatures and SBOMs discoverable.
  <br/><sub>the `subject` field, referrers API, discoverability</sub>

**[219 &middot; Pinning by Digest, Not Tag](219_digest_pinning/)** - Tags are for humans, digests are for machines. Enforce it as a test.
  <br/><sub>mutable tags, immutability policy, supply-chain risk</sub>

**[220 &middot; Diffing Two Images](220_image_diff/)** - Digests detect change; a diff explains it. Both belong in a promotion gate.
  <br/><sub>layer-level diff, file-level diff, "what actually changed?"</sub>


### Signing and supply chain  (251-300)

Real RSA and ECDSA signatures with openssl, signing image digests, attestations, SBOMs and verification gates that fail the build rather than a report nobody reads.

`bazel test //:signing`

**[251 &middot; Signing and Verifying With Real Keys](251_signing_basics/)** - Real cryptography as build actions. No mocking: this generates genuine RSA-2048 and ECDSA P-256 signatures and verifies them.
  <br/><sub>`openssl`, RSA vs ECDSA, detached signatures, verification as a test</sub>

**[271 &middot; Signing a Container Image](271_sign_oci_image/)** - Sign the manifest digest, and always verify that the signed payload refers to the image in front of you.
  <br/><sub>manifest digest, cosign payloads, binding a signature to an image</sub>


### Bare metal and firmware  (301-350)

Freestanding C, linker scripts, raw flash images via objcopy, boot headers, rollback protection and secure-boot style verification.

`bazel test //:firmware`

**[301 &middot; Bare-Metal Firmware](301_baremetal_basics/)** - No OS, no libc, no `main()`. This builds bytes intended to be written directly to flash.
  <br/><sub>freestanding C, linker scripts, `objcopy`, raw flash images</sub>

**[331 &middot; Signed Firmware and Secure Boot](331_signed_firmware/)** - Sign header and payload together, verify integrity before authenticity, and make rollback protection part of the signed region.
  <br/><sub>boot headers, rollback protection, signature over header+payload</sub>


### Parallel and matrix builds  (401-450)

Fanning one declaration out into many independent targets, multi-architecture matrices, and letting Bazel supply the concurrency instead of writing it yourself.

`bazel test //:parallel`

**[401 &middot; Building and Signing Many Images in Parallel](401_parallel_signed_images/)** - Fan-out is a macro plus independent targets. Bazel supplies the concurrency.
  <br/><sub>fan-out macros, independent targets, parallel signing</sub>


---

## Also here

- [docs/CONCEPTS.md](docs/CONCEPTS.md) - how the pieces fit together, plus a
  table of common failure modes and the example that explains each
- [docs/CHEATSHEET.md](docs/CHEATSHEET.md) - every Bazel command used here

## License

MIT - see [LICENSE](LICENSE). Use anything here however you like.

## Caveats

These are notes, not documentation. A few things I know are incomplete:

- Python coverage ([180](180_coverage_at_scale/)) reports zero line data here,
  because `rules_python` needs `configure_coverage_tool = True`. The example
  says so rather than pretending otherwise.
- `layering_check` ([167](167_layering_check/)) is described but not enabled -
  it needs Clang, and this machine has GCC.
- Remote caching and remote execution ([153](153_remote_cache/),
  [154](154_remote_execution/)) are configuration and explanation only; I had no
  cluster to point them at.

