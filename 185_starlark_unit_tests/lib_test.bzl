"""Unit tests for lib.bzl, using skylib's unittest framework."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(":lib.bzl", "merge_settings", "normalize_target_name", "split_flags")

# --- normalize_target_name ---------------------------------------------------

def _normalize_basic_test_impl(ctx):
    env = unittest.begin(ctx)

    asserts.equals(env, "my_target", normalize_target_name("My Target"))
    asserts.equals(env, "foo_bar", normalize_target_name("foo-bar"))
    asserts.equals(env, "a_b_c", normalize_target_name("a/b.c"))
    asserts.equals(env, "already_fine", normalize_target_name("already_fine"))

    return unittest.end(env)

normalize_basic_test = unittest.make(_normalize_basic_test_impl)

def _normalize_collapses_test_impl(ctx):
    env = unittest.begin(ctx)

    # Several separators in a row collapse to one underscore...
    asserts.equals(env, "a_b", normalize_target_name("a   ---   b"))
    # ...and leading/trailing separators are stripped.
    asserts.equals(env, "x", normalize_target_name("  x  "))

    return unittest.end(env)

normalize_collapses_test = unittest.make(_normalize_collapses_test_impl)

# --- split_flags -------------------------------------------------------------

def _split_flags_test_impl(ctx):
    env = unittest.begin(ctx)

    result = split_flags(["-DFOO", "-Wall", "-DBAR=1", "-O2"])
    asserts.equals(env, ["FOO", "BAR=1"], result.defines)
    asserts.equals(env, ["-Wall", "-O2"], result.others)

    empty = split_flags([])
    asserts.equals(env, [], empty.defines)
    asserts.equals(env, [], empty.others)

    return unittest.end(env)

split_flags_test = unittest.make(_split_flags_test_impl)

# --- merge_settings ----------------------------------------------------------

def _merge_settings_test_impl(ctx):
    env = unittest.begin(ctx)

    base = {"opt": "1", "debug": "0"}
    override = {"debug": "1", "trace": "1"}
    merged = merge_settings(base, override)

    asserts.equals(env, "1", merged["opt"])
    asserts.equals(env, "1", merged["debug"], "override should win")
    asserts.equals(env, "1", merged["trace"])

    # The inputs must not have been mutated.
    asserts.equals(env, "0", base["debug"], "base must not be modified")
    asserts.true(env, "trace" not in base)

    return unittest.end(env)

merge_settings_test = unittest.make(_merge_settings_test_impl)

# --- the suite ---------------------------------------------------------------

def lib_test_suite(name):
    """Declares every test above plus a test_suite gathering them."""
    unittest.suite(
        name,
        merge_settings_test,
        normalize_basic_test,
        normalize_collapses_test,
        split_flags_test,
    )
