"""Analysis tests for the capstone rule."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load(":defs.bzl", "ConfigInfo")

def _config_actions_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    asserts.true(env, ConfigInfo in target, "should provide ConfigInfo")

    actions = analysistest.target_actions(env)
    mnemonics = [a.mnemonic for a in actions]
    asserts.true(env, "GenConfig" in mnemonics, "should register a GenConfig action")
    asserts.true(env, "ValidateConfig" in mnemonics, "should register a validation action")

    files = target[DefaultInfo].files.to_list()
    asserts.equals(env, 1, len(files), "should declare exactly one header")
    asserts.true(env, files[0].basename.endswith(".h"))

    return analysistest.end(env)

config_actions_test = analysistest.make(_config_actions_test_impl)
