# 066 - http_archive: Depending on Non-Bazel Code

**Concepts:** `use_repo_rule`, `http_archive`, `build_file`, checksums

## Run it

```bash
bazel run //066_http_archive:compress
```

The first run downloads and extracts zlib 1.3.1, then compiles it from source.

## The declaration (in the root `MODULE.bazel`)

```python
http_archive = use_repo_rule("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "zlib_src",
    urls = ["https://github.com/madler/zlib/releases/download/v1.3.1/zlib-1.3.1.tar.gz"],
    sha256 = "9a93b2b7df...",
    strip_prefix = "zlib-1.3.1",
    build_file = "//066_http_archive:zlib.BUILD",
)
```

## `use_repo_rule` is the modern form

Under WORKSPACE you called `http_archive` directly. Under bzlmod, repository
rules can only run inside a module extension - and `use_repo_rule` is the
shorthand that creates a one-off extension for you. It is the right tool when
you need exactly one repository and no logic.

## The four attributes that matter

| Attribute | Why |
|-----------|-----|
| `urls` | A list, so you can add a mirror as a fallback |
| `sha256` | **Always set it.** See below. |
| `strip_prefix` | Archives usually contain a top-level `name-version/` dir |
| `build_file` | Supply a BUILD file for code that has none |

## Always pin the checksum

Omitting `sha256` makes the build non-hermetic: the upstream file can change
and your build silently changes with it. Bazel warns, and will re-download on
every cache miss instead of using the repository cache.

To find the right value, build once with a deliberately wrong checksum - the
error message tells you the real one:

```
Checksum was 9a93b2b7df... but wanted 0000...
```

## `build_file` vs `build_file_content`

```python
build_file = "//path:zlib.BUILD"        # a real, reviewable, syntax-highlighted file
build_file_content = "cc_library(...)"  # inline string; fine for 3 lines
```

Prefer `build_file` for anything non-trivial.

## Key takeaway

`http_archive` + a hand-written `build_file` is how any C/C++ tarball on the
internet becomes a first-class Bazel dependency.
