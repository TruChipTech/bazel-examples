"""bool_flag, int_flag and string_list_flag via skylib, plus label_flag."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

def _int_impl(ctx):
    return BuildSettingInfo(value = ctx.build_setting_value)

max_workers = rule(
    implementation = _int_impl,
    build_setting = config.int(flag = True),
)
