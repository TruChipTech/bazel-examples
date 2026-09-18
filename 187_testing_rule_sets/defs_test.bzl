"""Analysis-level tests for the csv_report rule."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load(":defs.bzl", "ReportInfo", "csv_report")

def _action_test_impl(ctx):
    env = analysistest.begin(ctx)

    # Inspect the ACTIONS the rule registered, without running them.
    actions = analysistest.target_actions(env)
    report_actions = [a for a in actions if a.mnemonic == "CsvReport"]

    asserts.equals(env, 1, len(report_actions), "expected exactly one CsvReport action")
    asserts.equals(env, 1, len(report_actions[0].outputs.to_list()))

    target = analysistest.target_under_test(env)
    asserts.true(env, ReportInfo in target)

    return analysistest.end(env)

action_test = analysistest.make(_action_test_impl)
