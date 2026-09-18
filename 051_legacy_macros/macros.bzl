"""A legacy macro: a plain Starlark function that calls rules."""

load("@rules_python//python:defs.bzl", "py_binary", "py_library", "py_test")

def py_module(name, srcs = None, deps = None, with_test = True, **kwargs):
    """Declares a library, an optional test, and a binary in one call.

    A macro is NOT a rule. It runs during the LOADING phase and simply expands
    into ordinary rule calls. Bazel never sees the macro - it only sees the
    targets the macro created.

    Args:
      name: base name; targets are <name>, <name>_test, <name>_bin.
      srcs: library sources. Defaults to <name>.py.
      deps: library dependencies.
      with_test: also declare <name>_test if the test file exists.
      **kwargs: forwarded to the library (visibility, tags, ...).
    """
    srcs = srcs or [name + ".py"]
    deps = deps or []

    py_library(
        name = name,
        srcs = srcs,
        imports = ["."],
        deps = deps,
        **kwargs
    )

    if with_test:
        py_test(
            name = name + "_test",
            srcs = [name + "_test.py"],
            imports = ["."],
            deps = [":" + name],
        )

    py_binary(
        name = name + "_bin",
        srcs = [name + "_main.py"],
        imports = ["."],
        main = name + "_main.py",
        deps = [":" + name],
    )
