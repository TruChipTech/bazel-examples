"""TemplateVariableInfo: defining your own Make variables."""

def _release_vars_impl(ctx):
    return [
        # TemplateVariableInfo publishes $(VAR) names that any target listing
        # this one in `toolchains = [...]` can use in cmd, copts, args, etc.
        platform_common.TemplateVariableInfo({
            "RELEASE_VERSION": ctx.attr.version,
            "RELEASE_CHANNEL": ctx.attr.channel,
            "VENDOR_NAME": ctx.attr.vendor,
        }),
    ]

release_vars = rule(
    implementation = _release_vars_impl,
    attrs = {
        "version": attr.string(mandatory = True),
        "channel": attr.string(default = "stable"),
        "vendor": attr.string(default = "acme"),
    },
)
