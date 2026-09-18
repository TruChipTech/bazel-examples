"""Emit a file whose CONTENT depends on the target platform."""

def _probe_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".txt")
    ctx.actions.write(
        output = out,
        # ctx.target_platform_has_constraint lets a rule branch on the platform
        # without a select() and without a config_setting per architecture.
        content = "cpu=%s\n" % (
            "aarch64" if ctx.target_platform_has_constraint(ctx.attr._aarch64[platform_common.ConstraintValueInfo]) else
            "armv7" if ctx.target_platform_has_constraint(ctx.attr._armv7[platform_common.ConstraintValueInfo]) else
            "x86_64"
        ),
    )
    return [DefaultInfo(files = depset([out]))]

arch_probe = rule(
    implementation = _probe_impl,
    attrs = {
        "_aarch64": attr.label(default = Label("@platforms//cpu:aarch64")),
        "_armv7": attr.label(default = Label("@platforms//cpu:armv7")),
    },
)
