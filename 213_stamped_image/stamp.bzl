"""Stamp provenance annotations into an image index."""

load("//201_oci_layout_basics:oci.bzl", "OciImageInfo")

def _stamped_impl(ctx):
    out = ctx.actions.declare_directory(ctx.label.name + "_layout")
    layout = ctx.attr.image[OciImageInfo].layout

    ctx.actions.run(
        # ctx.info_file is the STABLE status file (sample 091) - STABLE_ keys
        # only change when the source does, so they can safely feed an image.
        inputs = [layout, ctx.info_file],
        outputs = [out],
        executable = ctx.executable._stamper,
        arguments = [layout.path, ctx.info_file.path, out.path],
        mnemonic = "StampImage",
        progress_message = "Stamping %s" % ctx.label,
    )
    return [
        DefaultInfo(files = depset([out])),
        OciImageInfo(layout = out, ref = ctx.attr.image[OciImageInfo].ref),
    ]

stamped_image = rule(
    implementation = _stamped_impl,
    attrs = {
        "image": attr.label(providers = [OciImageInfo], mandatory = True),
        "_stamper": attr.label(
            default = Label("//213_stamped_image:stamp_index"),
            cfg = "exec",
            executable = True,
        ),
    },
)
