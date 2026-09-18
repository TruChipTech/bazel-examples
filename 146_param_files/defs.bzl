"""Parameter files: getting around operating-system command-line limits."""

def _many_args_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".txt")

    args = ctx.actions.args()
    args.add(out)

    # Generate a lot of arguments to make the limit realistic.
    for i in range(ctx.attr.count):
        args.add("--item=value_number_%d" % i)

    # use_param_file tells Bazel it MAY spill the command line into a file.
    #   "@%s"  - the conventional format: the tool receives @path
    #   use_always = True  - always use a param file, even for short commands
    #                        (useful for deterministic testing)
    args.use_param_file("@%s", use_always = ctx.attr.always)

    # The format of the file itself:
    #   "shell"      - shell-quoted, one line
    #   "multiline"  - one argument per line, no quoting (easier for tools)
    args.set_param_file_format("multiline")

    ctx.actions.run(
        outputs = [out],
        executable = ctx.executable._tool,
        arguments = [args],
        mnemonic = "ManyArgs",
        progress_message = "Running with %d arguments for %s" % (ctx.attr.count, ctx.label),
    )

    return [DefaultInfo(files = depset([out]))]

many_args = rule(
    implementation = _many_args_impl,
    attrs = {
        "count": attr.int(default = 10),
        "always": attr.bool(default = False),
        "_tool": attr.label(
            default = Label("//146_param_files:count_args"),
            cfg = "exec",
            executable = True,
        ),
    },
)
