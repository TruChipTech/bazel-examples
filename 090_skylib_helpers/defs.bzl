"""A tour of the bazel_skylib Starlark helper libraries."""

load("@bazel_skylib//lib:collections.bzl", "collections")
load("@bazel_skylib//lib:dicts.bzl", "dicts")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@bazel_skylib//lib:shell.bzl", "shell")
load("@bazel_skylib//lib:versions.bzl", "versions")

def demo_lines():
    """Returns a list of strings showing what each helper does."""
    lines = []

    # --- paths: manipulate path strings without string surgery ---------------
    lines.append("paths.join      = " + paths.join("src", "lib", "util.cc"))
    lines.append("paths.basename  = " + paths.basename("src/lib/util.cc"))
    lines.append("paths.dirname   = " + paths.dirname("src/lib/util.cc"))
    lines.append("paths.replace_ext = " + paths.replace_extension("util.cc", ".o"))
    lines.append("paths.normalize = " + paths.normalize("a/./b/../c"))

    # --- shell: quote values safely for a command line ----------------------
    dangerous = "file with spaces; rm -rf /"
    lines.append("shell.quote     = " + shell.quote(dangerous))

    # --- dicts: merge without mutating ---------------------------------------
    base = {"opt": "1", "debug": "0"}
    override = {"debug": "1"}
    merged = dicts.add(base, override)
    lines.append("dicts.add       = " + str(sorted(merged.items())))

    # --- collections: uniquify preserving order ------------------------------
    lines.append("collections.uniq = " + str(collections.uniq(["a", "b", "a", "c", "b"])))

    # --- versions: compare version strings -----------------------------------
    lines.append("versions.is_at_least(5.0, 9.2) = " + str(versions.is_at_least("5.0.0", "9.2.0")))

    return lines
