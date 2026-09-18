"""Composition patterns: building bigger rules out of smaller ones."""

load("@rules_python//python:defs.bzl", "py_binary", "py_library", "py_test")

# --- Pattern 1: a macro composing existing rules ------------------------------
# The simplest and most common. No new rule type; just a convention.

def _service_impl(name, visibility, srcs, main, test_srcs, deps, **kwargs):
    py_library(
        name = name + "_lib",
        srcs = srcs,
        imports = ["."],
        visibility = visibility,
        deps = deps,
    )

    py_binary(
        name = name,
        srcs = [main],
        imports = ["."],
        main = main,
        visibility = visibility,
        deps = [":" + name + "_lib"],
    )

    if test_srcs:
        py_test(
            name = name + "_test",
            srcs = test_srcs,
            imports = ["."],
            deps = [":" + name + "_lib"],
            **kwargs
        )

python_service = macro(
    implementation = _service_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".py"], mandatory = True),
        "main": attr.label(allow_single_file = [".py"], mandatory = True, configurable = False),
        "test_srcs": attr.label_list(allow_files = [".py"], default = [], configurable = False),
        "deps": attr.label_list(default = [], configurable = False),
    },
)

# --- Pattern 2: a rule composing PROVIDERS from several rules -----------------

BundleInfo = provider(fields = {"parts": "depset of File"})

def _bundle_impl(ctx):
    parts = depset(transitive = [
        t[DefaultInfo].files
        for t in ctx.attr.parts
    ])

    manifest = ctx.actions.declare_file(ctx.label.name + ".manifest")
    ctx.actions.write(
        output = manifest,
        content = "\n".join(sorted([f.short_path for f in parts.to_list()])) + "\n",
    )

    return [
        DefaultInfo(files = depset([manifest], transitive = [parts])),
        BundleInfo(parts = parts),
    ]

bundle = rule(
    implementation = _bundle_impl,
    attrs = {
        "parts": attr.label_list(mandatory = True),
    },
)
