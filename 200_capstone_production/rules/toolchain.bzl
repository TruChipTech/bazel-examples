"""Toolchain carrying the config generator."""

def _config_toolchain_impl(ctx):
    return [platform_common.ToolchainInfo(
        generator = ctx.attr.generator[DefaultInfo].files_to_run,
        flavor = ctx.attr.flavor,
    )]

config_toolchain = rule(
    implementation = _config_toolchain_impl,
    attrs = {
        "generator": attr.label(mandatory = True, cfg = "exec", executable = True),
        "flavor": attr.string(mandatory = True),
    },
)

TOOLCHAIN_TYPE = "//200_capstone_production/toolchain:config_toolchain_type"
