"""A toolchain that carries an actual executable tool."""

def _compiler_toolchain_impl(ctx):
    return [
        platform_common.ToolchainInfo(
            # Carrying a File (the tool) means the consumer does not need to
            # know where the tool lives or how it was built.
            compiler = ctx.executable.compiler,
            # Files the action needs must be passed along too, so the consumer
            # can add them to the action's inputs.
            compiler_files = ctx.attr.compiler[DefaultInfo].files_to_run,
            flavor = ctx.attr.flavor,
        ),
    ]

compiler_toolchain = rule(
    implementation = _compiler_toolchain_impl,
    attrs = {
        "compiler": attr.label(
            mandatory = True,
            cfg = "exec",
            executable = True,
        ),
        "flavor": attr.string(mandatory = True),
    },
)

TOOLCHAIN_TYPE = "//124_custom_toolchain:compiler_type"

def _compile_impl(ctx):
    toolchain = ctx.toolchains[TOOLCHAIN_TYPE]
    out = ctx.actions.declare_file(ctx.label.name + ".out")

    # Passing the FilesToRunProvider as `executable` is the idiomatic form:
    # Bazel then stages the executable AND its runfiles automatically, so no
    # separate `tools` entry is needed.
    ctx.actions.run(
        inputs = [ctx.file.src],
        outputs = [out],
        executable = toolchain.compiler_files,
        arguments = [ctx.file.src.path, out.path],
        mnemonic = "MiniCompile",
        progress_message = "Compiling %s with the %s compiler" % (
            ctx.label,
            toolchain.flavor,
        ),
    )

    return [DefaultInfo(files = depset([out]))]

mini_compile = rule(
    implementation = _compile_impl,
    attrs = {"src": attr.label(allow_single_file = True, mandatory = True)},
    toolchains = [TOOLCHAIN_TYPE],
)
