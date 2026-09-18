"""Using the `native` module inside macros."""

load("@rules_python//python:defs.bzl", "py_library", "py_test")

def auto_test_suite(name, test_files):
    """Declares one py_test per file, plus a suite containing them all.

    Inside a .bzl file, rules that Bazel provides natively (filegroup,
    test_suite, genrule, alias, ...) are reached through `native.`:
        native.filegroup(...)
        native.test_suite(...)

    In a BUILD file you write them WITHOUT the prefix. The prefix exists
    because .bzl files have no implicit BUILD-file namespace.
    """
    test_names = []
    for src in test_files:
        test_name = src.replace(".py", "")
        py_test(
            name = test_name,
            size = "small",
            srcs = [src],
            imports = ["."],
            deps = [":" + name + "_lib"],
        )
        test_names.append(":" + test_name)

    # native.test_suite - no load() needed, but the prefix is required here.
    native.test_suite(
        name = name,
        tests = test_names,
    )

def library_with_tests(name, srcs, test_files):
    py_library(
        name = name + "_lib",
        srcs = srcs,
        imports = ["."],
    )
    auto_test_suite(name = name, test_files = test_files)

def package_info():
    """native.package_name() and friends report where the macro was called."""

    # These are only valid during the loading phase.
    return struct(
        package = native.package_name(),
        repo = native.repository_name(),
    )
