"""DefaultInfo: what a target offers by default."""

def _bundle_impl(ctx):
    primary = ctx.actions.declare_file(ctx.label.name + ".bundle")
    extra = ctx.actions.declare_file(ctx.label.name + ".index")

    ctx.actions.write(
        output = primary,
        content = "bundle: %s\nfiles: %d\n" % (
            ctx.label.name,
            len(ctx.files.srcs),
        ),
    )
    ctx.actions.write(
        output = extra,
        content = "\n".join([f.basename for f in ctx.files.srcs]) + "\n",
    )

    return [
        DefaultInfo(
            # files: what `bazel build //this:target` produces, and what a
            # consumer gets when it lists this target in srcs.
            files = depset([primary, extra]),

            # runfiles: what is staged next to a binary that depends on this
            # target via `data`. Note these are DIFFERENT sets - a bundle's
            # index might be a build output but not needed at runtime.
            runfiles = ctx.runfiles(files = ctx.files.srcs + [primary]),
        ),
    ]

bundle = rule(
    implementation = _bundle_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True, mandatory = True),
    },
)
