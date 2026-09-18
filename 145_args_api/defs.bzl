"""The Args API: building command lines efficiently."""

def _args_demo_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".txt")

    args = ctx.actions.args()

    # add: one value. A File becomes its exec path automatically.
    args.add(out)
    args.add("--mode", ctx.attr.mode)

    # add_all: expand a list or DEPSET. No to_list() needed - the expansion is
    # deferred until the action runs.
    args.add_all("--src", ctx.files.srcs)

    # format_each: apply a format string to every element.
    args.add_all(ctx.files.srcs, format_each = "--input=%s")

    # map_each: transform each element with a Starlark function. The function
    # runs at EXECUTION time, not analysis time - so it does not cost anything
    # for actions that never run.
    args.add_all(ctx.files.srcs, map_each = _basename_only, format_each = "--name=%s")

    # add_joined: collapse a list into one argument.
    args.add_joined("--all", ctx.files.srcs, join_with = ",", map_each = _basename_only)

    # uniquify removes duplicates; omit_if_empty avoids a dangling flag.
    args.add_all("--tag", ctx.attr.tags_list, uniquify = True, omit_if_empty = True)

    ctx.actions.run(
        inputs = ctx.files.srcs,
        outputs = [out],
        executable = ctx.executable._collector,
        arguments = [args],
        mnemonic = "ArgsDemo",
        progress_message = "Building a command line for %s" % ctx.label,
    )

    return [DefaultInfo(files = depset([out]))]

def _basename_only(f):
    return f.basename

args_demo = rule(
    implementation = _args_demo_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True, mandatory = True),
        "mode": attr.string(default = "normal"),
        "tags_list": attr.string_list(default = []),
        "_collector": attr.label(
            default = Label("//145_args_api:collect"),
            cfg = "exec",
            executable = True,
        ),
    },
)
