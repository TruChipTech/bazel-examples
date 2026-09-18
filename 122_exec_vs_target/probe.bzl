"""The exec configuration vs the target configuration."""

def _probe_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".txt")

    # ctx.bin_dir.path encodes the CONFIGURATION of this target. A tool built
    # in the exec configuration lands in a different directory than the same
    # tool built for the target platform - which is why both can coexist.
    lines = [
        "target label      : %s" % ctx.label,
        "bin dir           : %s" % ctx.bin_dir.path,
        "exec tool path    : %s" % ctx.executable._exec_tool.path,
        "target tool path  : %s" % ctx.executable.target_tool.path,
        "",
        "Note the differing path segments: the exec tool is built for the",
        "machine running the build; the target tool for the output platform.",
    ]

    ctx.actions.write(output = out, content = "\n".join(lines) + "\n")
    return [DefaultInfo(files = depset([out]))]

config_probe = rule(
    implementation = _probe_impl,
    attrs = {
        "target_tool": attr.label(
            mandatory = True,
            # cfg = "target" (the default): built for the platform the output
            # is FOR. Correct for things that ship with the product.
            cfg = "target",
            executable = True,
        ),
        "_exec_tool": attr.label(
            default = Label("//122_exec_vs_target:helper"),
            # cfg = "exec": built for the machine RUNNING the build. Correct
            # for anything an action executes.
            cfg = "exec",
            executable = True,
        ),
    },
)
