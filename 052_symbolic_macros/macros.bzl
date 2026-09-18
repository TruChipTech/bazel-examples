"""Symbolic macros: the modern, introspectable form of a macro."""

load("@rules_python//python:defs.bzl", "py_binary", "py_library")

def _service_impl(name, visibility, srcs, main, port, extra_deps, **kwargs):
    """Implementation function. Note `name` and `visibility` are explicit."""

    py_library(
        name = name + "_lib",
        srcs = srcs,
        imports = ["."],
        # Targets a symbolic macro creates are PRIVATE by default unless you
        # pass visibility explicitly. That is the key difference from legacy
        # macros, where everything leaked.
        visibility = visibility,
        deps = extra_deps,
    )

    py_binary(
        name = name,
        srcs = [main],
        args = ["--port", str(port)],
        imports = ["."],
        main = main,
        visibility = visibility,
        deps = [":" + name + "_lib"],
    )

# macro() declares the attribute schema up front, so Bazel can validate calls
# and tooling can see the structure without executing arbitrary code.
#
# NOTE: a symbolic macro may only use labels that were PASSED IN as attributes.
# It cannot name a sibling file like "api_main.py" out of thin air the way a
# legacy macro can - hence the explicit `main` attribute below.
service = macro(
    implementation = _service_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".py"], mandatory = True),
        "main": attr.label(allow_single_file = [".py"], mandatory = True, configurable = False),
        "port": attr.int(default = 8080, configurable = False),
        "extra_deps": attr.label_list(default = [], configurable = False),
    },
)
