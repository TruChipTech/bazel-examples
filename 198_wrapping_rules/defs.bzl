"""Wrapping an existing rule to add project-wide policy."""

load("@rules_cc//cc:defs.bzl", _cc_binary = "cc_binary", _cc_library = "cc_library", _cc_test = "cc_test")

# Project-wide standards, defined once.
STANDARD_COPTS = [
    "-Wall",
    "-Wextra",
]

STANDARD_TEST_TAGS = ["unit"]

def cc_library(name, copts = [], **kwargs):
    """cc_library with the project's warning flags applied.

    Because it has the SAME NAME as the rule it wraps, BUILD files change only
    their load() statement - not a single target.
    """
    _cc_library(
        name = name,
        copts = STANDARD_COPTS + copts,
        **kwargs
    )

def cc_binary(name, copts = [], **kwargs):
    _cc_binary(
        name = name,
        copts = STANDARD_COPTS + copts,
        **kwargs
    )

def cc_test(name, copts = [], tags = [], size = "small", **kwargs):
    """cc_test with standard flags, a default size, and standard tags."""
    _cc_test(
        name = name,
        size = size,
        copts = STANDARD_COPTS + copts,
        tags = STANDARD_TEST_TAGS + tags,
        **kwargs
    )
