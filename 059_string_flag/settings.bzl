"""Custom build settings - user-definable flags."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

def _backend_impl(ctx):
    # A build setting's implementation simply reports its value.
    return BuildSettingInfo(value = ctx.build_setting_value)

backend_flag = rule(
    implementation = _backend_impl,
    # build_setting marks this rule as a FLAG rather than a normal target.
    # flag = True makes it settable on the command line.
    build_setting = config.string(flag = True),
)
