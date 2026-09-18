"""Exec groups: different actions in one rule, different execution requirements."""

def _multi_step_impl(ctx):
    compiled = ctx.actions.declare_file(ctx.label.name + ".compiled")
    linked = ctx.actions.declare_file(ctx.label.name + ".linked")

    # This action is declared in the "compile" exec group, so it can be routed
    # to an execution platform (or given execution requirements) independently
    # of the link step.
    ctx.actions.run_shell(
        inputs = [ctx.file.src],
        outputs = [compiled],
        arguments = [ctx.file.src.path, compiled.path],
        command = 'echo "compiled from $(basename "$1")" > "$2"',
        mnemonic = "MultiCompile",
        exec_group = "compile",
        progress_message = "Compiling %s" % ctx.label,
    )

    # The link step is typically memory-hungry and hard to parallelize, so it
    # often wants a different machine class than compilation.
    ctx.actions.run_shell(
        inputs = [compiled],
        outputs = [linked],
        arguments = [compiled.path, linked.path],
        command = 'cat "$1" > "$2" && echo "linked" >> "$2"',
        mnemonic = "MultiLink",
        exec_group = "link",
        progress_message = "Linking %s" % ctx.label,
    )

    return [DefaultInfo(files = depset([linked]))]

multi_step = rule(
    implementation = _multi_step_impl,
    attrs = {"src": attr.label(allow_single_file = True, mandatory = True)},
    exec_groups = {
        # Each group can require its own execution-platform constraints and
        # resolve its own toolchains.
        "compile": exec_group(),
        "link": exec_group(),
    },
)
