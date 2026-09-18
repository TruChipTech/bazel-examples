"""declare_directory - outputs whose file list is not known at analysis time."""

def _site_impl(ctx):
    # A "tree artifact": Bazel tracks the DIRECTORY, not individual files.
    # Use it when the set of outputs depends on the tool's behavior and cannot
    # be enumerated during analysis.
    outdir = ctx.actions.declare_directory(ctx.label.name + "_site")

    args = ctx.actions.args()
    args.add(outdir.path)
    args.add_all(ctx.attr.pages)

    ctx.actions.run(
        outputs = [outdir],
        executable = ctx.executable._generator,
        arguments = [args],
        mnemonic = "GenSite",
        progress_message = "Generating site %s" % ctx.label,
    )

    return [DefaultInfo(files = depset([outdir]))]

static_site = rule(
    implementation = _site_impl,
    attrs = {
        "pages": attr.string_list(mandatory = True),
        "_generator": attr.label(
            default = Label("//108_declare_directory:gen_site"),
            cfg = "exec",
            executable = True,
        ),
    },
)
