"""A minimal oci_image rule: assembles a spec-compliant OCI image layout.

The whole image is ONE tree artifact (sample 108), because the set of blob
filenames is not knowable until the digests are computed - which happens when
the action runs, not during analysis.
"""

OciImageInfo = provider(
    doc = "An assembled OCI image layout.",
    fields = {
        "layout": "File - the image layout directory (tree artifact)",
        "ref": "string - the tag annotation written into index.json",
    },
)

def _oci_image_impl(ctx):
    layout = ctx.actions.declare_directory(ctx.label.name + "_layout")

    args = ctx.actions.args()
    args.add(layout.path)
    args.add(ctx.attr.ref)
    args.add(ctx.attr.entrypoint)
    args.add_all(ctx.files.layers)

    ctx.actions.run(
        inputs = ctx.files.layers,
        outputs = [layout],
        executable = ctx.executable._mkoci,
        arguments = [args],
        mnemonic = "OciImage",
        progress_message = "Assembling OCI image %s" % ctx.label,
    )

    return [
        DefaultInfo(files = depset([layout])),
        OciImageInfo(layout = layout, ref = ctx.attr.ref),
    ]

oci_image = rule(
    implementation = _oci_image_impl,
    attrs = {
        "layers": attr.label_list(allow_files = True, mandatory = True),
        "entrypoint": attr.string(mandatory = True),
        "ref": attr.string(default = "latest"),
        "_mkoci": attr.label(
            default = Label("//201_oci_layout_basics:mkoci"),
            cfg = "exec",
            executable = True,
        ),
    },
    provides = [OciImageInfo],
)
