"""ctx.actions.run - executing a tool as a build action."""

def _wordfreq_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".txt")

    # ctx.actions.args() builds a command line efficiently. It can be lazily
    # expanded and spilled to a param file (sample 146) - prefer it over a
    # plain Python list for anything that could grow large.
    args = ctx.actions.args()
    args.add(out)           # File -> its exec path
    args.add_all(ctx.files.srcs)

    ctx.actions.run(
        # Every file the tool reads MUST be listed. The sandbox contains
        # nothing else.
        inputs = ctx.files.srcs,
        outputs = [out],

        # executable accepts a File. ctx.executable.<attr> gives the runnable
        # file of a label attribute declared with executable = True.
        executable = ctx.executable.tool,
        arguments = [args],

        # Shown in build output and used by --subcommands / aquery filtering.
        mnemonic = "WordFreq",
        progress_message = "Counting words for %s" % ctx.label,
    )

    return [DefaultInfo(files = depset([out]))]

wordfreq = rule(
    implementation = _wordfreq_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True, mandatory = True),
        "tool": attr.label(
            default = Label("//105_actions_run:wordfreq"),
            # cfg = "exec" builds the tool for the machine RUNNING the build,
            # not the machine the output targets. Essential for cross-compiling.
            cfg = "exec",
            executable = True,
        ),
    },
)
