"""Macros layered on top of constants.bzl."""

load("@rules_cc//cc:defs.bzl", "cc_library")
load(":constants.bzl", "DEFAULT_COPTS")

def strict_cc_library(name, **kwargs):
    """A cc_library with the project's standard warning flags applied."""
    copts = kwargs.pop("copts", [])
    cc_library(
        name = name,
        copts = DEFAULT_COPTS + copts,
        **kwargs
    )
