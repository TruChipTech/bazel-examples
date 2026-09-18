"""Reading build settings from inside a rule implementation."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

def _tuned_binary_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".conf")

    # A rule reads a build setting by depending on it through an attribute and
    # pulling BuildSettingInfo off the resulting Target.
    opt_level = ctx.attr._opt_level[BuildSettingInfo].value
    tracing = ctx.attr._tracing[BuildSettingInfo].value

    # ctx.var exposes Make variables, including --define values.
    compilation_mode = ctx.var.get("COMPILATION_MODE", "unknown")

    lines = [
        "opt_level        = %s" % opt_level,
        "tracing          = %s" % tracing,
        "compilation_mode = %s" % compilation_mode,
        "derived_flags    = %s" % ",".join(_flags_for(opt_level, tracing)),
    ]

    ctx.actions.write(output = out, content = "\n".join(lines) + "\n")
    return [DefaultInfo(files = depset([out]))]

def _flags_for(opt_level, tracing):
    flags = ["-O" + opt_level]
    if tracing:
        flags.append("-DENABLE_TRACING")
        flags.append("-fno-omit-frame-pointer")
    return flags

tuned_binary = rule(
    implementation = _tuned_binary_impl,
    attrs = {
        # Private label attributes pointing at the build settings. Consumers
        # never set these; they set the FLAGS on the command line.
        "_opt_level": attr.label(
            default = Label("//140_build_settings_in_rules:opt_level"),
        ),
        "_tracing": attr.label(
            default = Label("//140_build_settings_in_rules:tracing"),
        ),
    },
)
