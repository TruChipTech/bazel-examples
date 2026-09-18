"""Build a multi-arch image index from several single-arch images."""

load("//201_oci_layout_basics:oci.bzl", "OciImageInfo")

def _index_impl(ctx):
    out = ctx.actions.declare_directory(ctx.label.name + "_layout")
    args = ctx.actions.args()
    args.add(out.path)
    args.add(ctx.attr.ref)

    layouts = []
    for platform, target in ctx.attr.images.items():
        layout = target[OciImageInfo].layout
        layouts.append(layout)
        args.add("%s=%s" % (platform, layout.path))

    ctx.actions.run(
        inputs = layouts,
        outputs = [out],
        executable = ctx.executable._mkindex,
        arguments = [args],
        mnemonic = "OciIndex",
        progress_message = "Building multi-arch index %s" % ctx.label,
    )
    return [DefaultInfo(files = depset([out]))]

oci_index = rule(
    implementation = _index_impl,
    attrs = {
        # label_keyed_string_dict reversed: platform string -> image target
        "images": attr.string_keyed_label_dict(allow_files = True, mandatory = True),
        "ref": attr.string(default = "latest"),
        "_mkindex": attr.label(
            default = Label("//205_multiarch_index:mkindex"),
            cfg = "exec",
            executable = True,
        ),
    },
)
