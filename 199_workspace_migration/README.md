# 199 - Migrating From WORKSPACE to bzlmod

**Concepts:** the migration path, common conversions

## The situation

Bazel 9 **removed WORKSPACE entirely**. There is no `--enable_workspace`
fallback. A repo still on WORKSPACE cannot use Bazel 9 at all, so this
migration is mandatory rather than optional.

The good news: it is mostly mechanical, and Bazel 7/8 let you run both systems
side by side while you do it.

## The conversion table

| WORKSPACE | MODULE.bazel |
|-----------|--------------|
| `http_archive(name="rules_cc", ...)` for a registry module | `bazel_dep(name = "rules_cc", version = "0.2.17")` |
| `http_archive` for something not in the registry | `use_repo_rule` + `http_archive` (sample 066) |
| `git_repository` | `git_override`, or `use_repo_rule` |
| `local_repository` | `local_path_override` (sample 068) |
| A `deps()` macro chain | `bazel_dep` - transitive deps resolve automatically |
| `register_toolchains(...)` | `register_toolchains(...)` (unchanged) |
| Custom repository rules | A module extension (sample 070) |
| `maybe(http_archive, ...)` | Nothing - MVS handles duplicates |

## The biggest simplification

WORKSPACE required you to manually load every dependency's dependencies:

```python
# WORKSPACE - the "deps() chain" everyone had
load("@rules_foo//:deps.bzl", "rules_foo_dependencies")
rules_foo_dependencies()
load("@rules_foo//:setup.bzl", "rules_foo_setup")
rules_foo_setup()
load("@rules_bar//:deps.bzl", "rules_bar_dependencies")
rules_bar_dependencies()
# ... and the ORDER mattered, and conflicts were silent
```

```python
# MODULE.bazel
bazel_dep(name = "rules_foo", version = "1.0.0")
bazel_dep(name = "rules_bar", version = "2.0.0")
```

That is the whole thing. Transitive dependencies resolve themselves, and
version conflicts are resolved by MVS (sample 164) instead of by whoever loaded
first.

## The procedure

**1. Find the current versions.**
```bash
bazel mod graph        # on Bazel 7/8 with bzlmod enabled
```
Or look up each dependency at https://registry.bazel.build.

**2. Add `bazel_dep` for everything available in the registry.** Most rule sets
are there.

**3. Convert what is not.**
```python
http_archive = use_repo_rule("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "some_c_library",
    urls = [...],
    sha256 = "...",
    strip_prefix = "...",
    build_file = "//third_party:some_c_library.BUILD",
)
```

**4. Convert custom repository logic to a module extension** (sample 137).

**5. Fix repository names.** This is where the real work is.

## Repository names change

```
WORKSPACE:  @com_google_absl
bzlmod:     @abseil-cpp
```

Options:

```python
# Keep old labels working during migration
bazel_dep(name = "abseil-cpp", version = "20240722.0", repo_name = "com_google_absl")
```

`repo_name` (sample 067) lets thousands of existing labels keep working while
you migrate them gradually. Remove it once the labels are updated.

**Canonical names also appear in error messages:**
```
@@rules_cc+//:foo        # bzlmod canonical form
```
Never type these in BUILD files - use the apparent name.

## Native rules are gone too

Bazel 9 removed the built-in language rules. Every BUILD file needs loads:

```python
load("@rules_cc//cc:defs.bzl", "cc_binary", "cc_library", "cc_test")
load("@rules_python//python:defs.bzl", "py_binary", "py_library", "py_test")
load("@rules_java//java:defs.bzl", "java_binary", "java_library", "java_test")
load("@rules_shell//shell:sh_binary.bzl", "sh_binary")
load("@protobuf//bazel:proto_library.bzl", "proto_library")
```

Provider globals moved too:
```python
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")
```

`buildifier --lint=fix -r .` adds most of these automatically, and Bazel's
error messages name the exact load line to add.

## Tools

```bash
buildifier --lint=fix -r .     # add missing load() statements
bazel mod tidy                 # fix use_repo() calls
bazel mod graph                # verify the result
```

## Verify

```bash
bazel build //... --lockfile_mode=update
bazel test //...
git diff MODULE.bazel.lock     # commit it
```

## Key takeaway

`bazel_dep` replaces `http_archive` plus the whole `deps()` chain. The
migration work is repository renames and adding `load()` statements - both
largely automatable.
