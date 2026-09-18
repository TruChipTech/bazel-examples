"""Cross-compilation with a toy toolchain, to show the mechanics."""

def _codegen_toolchain_impl(ctx):
    return [platform_common.ToolchainInfo(
        arch_name = ctx.attr.arch_name,
        word_size = ctx.attr.word_size,
    )]

codegen_toolchain = rule(
    implementation = _codegen_toolchain_impl,
    attrs = {
        "arch_name": attr.string(mandatory = True),
        "word_size": attr.int(mandatory = True),
    },
)

TYPE = "//129_cross_compilation:codegen_type"

def _arch_header_impl(ctx):
    tc = ctx.toolchains[TYPE]
    out = ctx.actions.declare_file(ctx.label.name + ".h")

    ctx.actions.write(
        output = out,
        content = """// GENERATED for %s
#define TARGET_ARCH "%s"
#define TARGET_WORD_SIZE %d
""" % (tc.arch_name, tc.arch_name, tc.word_size),
    )
    return [DefaultInfo(files = depset([out]))]

arch_header = rule(
    implementation = _arch_header_impl,
    toolchains = [TYPE],
)
