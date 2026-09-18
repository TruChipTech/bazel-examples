"""Toolchain type and implementation for the recipe rule set."""

def _recipe_toolchain_impl(ctx):
    return [platform_common.ToolchainInfo(
        compiler = ctx.attr.compiler[DefaultInfo].files_to_run,
        linter = ctx.attr.linter[DefaultInfo].files_to_run,
        flavor = ctx.attr.flavor,
    )]

recipe_toolchain = rule(
    implementation = _recipe_toolchain_impl,
    attrs = {
        "compiler": attr.label(mandatory = True, cfg = "exec", executable = True),
        "linter": attr.label(mandatory = True, cfg = "exec", executable = True),
        "flavor": attr.string(mandatory = True),
    },
)

TOOLCHAIN_TYPE = "//150_capstone_rule_set/toolchain:recipe_toolchain_type"
