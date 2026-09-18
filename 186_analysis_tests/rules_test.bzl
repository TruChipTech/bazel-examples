"""analysistest: testing what a RULE produces, not just Starlark functions."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load(":rules.bzl", "TagInfo", "tagged_file")

# --- Test 1: the provider is populated correctly -----------------------------

def _provider_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    asserts.true(env, TagInfo in target, "target should provide TagInfo")
    info = target[TagInfo]
    asserts.equals(env, "release", info.tag)
    asserts.equals(env, 3, info.count)

    return analysistest.end(env)

provider_test = analysistest.make(_provider_test_impl)

# --- Test 2: the declared outputs are what we expect --------------------------

def _outputs_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    files = target[DefaultInfo].files.to_list()
    asserts.equals(env, 1, len(files), "should declare exactly one output")
    asserts.true(
        env,
        files[0].basename.endswith(".txt"),
        "output should be a .txt file, got " + files[0].basename,
    )

    return analysistest.end(env)

outputs_test = analysistest.make(_outputs_test_impl)

# --- Test 3: the rule FAILS on invalid input ---------------------------------

def _failure_test_impl(ctx):
    env = analysistest.begin(ctx)
    # expect_failure asserts that analysis failed with a matching message.
    asserts.expect_failure(env, "count must not be negative")
    return analysistest.end(env)

failure_test = analysistest.make(
    _failure_test_impl,
    # expect_failure = True is what allows the target under test to fail
    # analysis without failing the test.
    expect_failure = True,
)

# --- Wiring ------------------------------------------------------------------

def rules_test_suite(name):
    # The targets UNDER TEST. They are tagged manual so `bazel build //...`
    # does not try to build the deliberately broken one.
    tagged_file(
        name = "subject_ok",
        count = 3,
        tag = "release",
        tags = ["manual"],
    )

    tagged_file(
        name = "subject_bad",
        count = -1,
        tag = "broken",
        tags = ["manual"],
    )

    provider_test(name = "provider_test", target_under_test = ":subject_ok")
    outputs_test(name = "outputs_test", target_under_test = ":subject_ok")
    failure_test(name = "failure_test", target_under_test = ":subject_bad")

    native.test_suite(
        name = name,
        tests = [
            ":failure_test",
            ":outputs_test",
            ":provider_test",
        ],
    )
