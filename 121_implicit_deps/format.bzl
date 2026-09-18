"""Implicit dependencies: tools the rule needs but callers never mention."""

def _formatted_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".txt")

    ctx.actions.run(
        inputs = [ctx.file.src],
        outputs = [out],
        # ctx.executable._formatter - the leading underscore marks it private.
        executable = ctx.executable._formatter,
        arguments = [ctx.file.src.path, out.path],
        mnemonic = "Format",
        progress_message = "Formatting %s" % ctx.label,
    )

    return [DefaultInfo(files = depset([out]))]

formatted = rule(
    implementation = _formatted_impl,
    attrs = {
        "src": attr.label(allow_single_file = True, mandatory = True),

        # An IMPLICIT DEPENDENCY: the name starts with "_", so callers cannot
        # set it. The rule always uses this tool. It still becomes a real edge
        # in the build graph, so the tool is built automatically and appears in
        # `bazel query 'deps(...)'`.
        "_formatter": attr.label(
            default = Label("//121_implicit_deps:formatter"),
            cfg = "exec",
            executable = True,
            allow_files = True,
        ),
    },
)
