"""Defining a toolchain type and a concrete toolchain."""

# The PROVIDER that carries the toolchain's data.
GreeterToolchainInfo = provider(
    doc = "Configuration for a greeter implementation.",
    fields = {
        "greeting": "string - the greeting word",
        "punctuation": "string - trailing punctuation",
        "language": "string - human language name",
    },
)

def _greeter_toolchain_impl(ctx):
    # A toolchain rule wraps its data in ToolchainInfo. Consumers reach the
    # fields through ctx.toolchains[<type>].
    return [
        platform_common.ToolchainInfo(
            greeter_info = GreeterToolchainInfo(
                greeting = ctx.attr.greeting,
                punctuation = ctx.attr.punctuation,
                language = ctx.attr.language,
            ),
        ),
    ]

greeter_toolchain = rule(
    implementation = _greeter_toolchain_impl,
    attrs = {
        "greeting": attr.string(mandatory = True),
        "punctuation": attr.string(default = "!"),
        "language": attr.string(mandatory = True),
    },
)

# --- A rule that USES the toolchain -----------------------------------------

def _greet_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".txt")

    # ctx.toolchains[<toolchain_type label>] - resolved automatically by Bazel
    # based on the target platform and the registered toolchains.
    info = ctx.toolchains["//123_toolchain_basics:greeter_toolchain_type"].greeter_info

    ctx.actions.write(
        output = out,
        content = "%s, %s%s  (language: %s)\n" % (
            info.greeting,
            ctx.attr.who,
            info.punctuation,
            info.language,
        ),
    )
    return [DefaultInfo(files = depset([out]))]

greet = rule(
    implementation = _greet_impl,
    attrs = {"who": attr.string(default = "world")},
    # Declaring the toolchain type is what makes Bazel resolve one.
    toolchains = ["//123_toolchain_basics:greeter_toolchain_type"],
)
