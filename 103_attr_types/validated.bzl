"""Attribute validation: constraining values at analysis time."""

# In Bazel 9 CcInfo is no longer a global - it must be loaded from rules_cc.
load("@rules_cc//cc/common:cc_info.bzl", "CcInfo")

def _validated_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".conf")

    # Validation beyond what attr.* can express belongs in the implementation,
    # using fail() to produce a clear message.
    if ctx.attr.replicas > 100:
        fail("%s: replicas=%d exceeds the maximum of 100" % (
            ctx.label,
            ctx.attr.replicas,
        ))

    if ctx.attr.tier == "premium" and ctx.attr.replicas < 2:
        fail("%s: premium tier requires at least 2 replicas" % ctx.label)

    content = "\n".join([
        "tier=%s" % ctx.attr.tier,
        "replicas=%d" % ctx.attr.replicas,
        "region=%s" % ctx.attr.region,
    ])
    ctx.actions.write(output = out, content = content + "\n")
    return [DefaultInfo(files = depset([out]))]

validated_config = rule(
    implementation = _validated_impl,
    attrs = {
        # `values` restricts a string to an allowlist. A bad value is rejected
        # during ANALYSIS with a good message - no implementation code needed.
        "tier": attr.string(
            default = "standard",
            values = [
                "basic",
                "premium",
                "standard",
            ],
        ),
        "region": attr.string(
            mandatory = True,
            values = [
                "eu-west",
                "us-east",
                "us-west",
            ],
        ),
        "replicas": attr.int(default = 1),

        # allow_files can restrict by EXTENSION.
        "cert": attr.label(allow_single_file = [
            ".pem",
            ".crt",
        ]),

        # providers requires that each dependency provides a given provider.
        # This is how a rule says "deps must be cc_library-like".
        "deps": attr.label_list(providers = [CcInfo]),
    },
)
