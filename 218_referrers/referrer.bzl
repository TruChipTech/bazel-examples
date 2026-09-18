"""Attach an artifact to an image via the `subject` field."""

load("//201_oci_layout_basics:oci.bzl", "OciImageInfo")
load("//271_sign_oci_image:sign_image.bzl", "SignedImageInfo")

def _referrer_impl(ctx):
    out = ctx.actions.declare_directory(ctx.label.name + "_layout")
    signed = ctx.attr.signed_image[SignedImageInfo]

    ctx.actions.run(
        inputs = [signed.layout, signed.payload],
        outputs = [out],
        executable = ctx.executable._mkreferrer,
        arguments = [out.path, signed.layout.path, ctx.attr.artifact_type, signed.payload.path],
        mnemonic = "OciReferrer",
        progress_message = "Attaching %s to its image" % ctx.label,
    )
    return [DefaultInfo(files = depset([out]))]

attach_signature = rule(
    implementation = _referrer_impl,
    attrs = {
        "signed_image": attr.label(providers = [SignedImageInfo], mandatory = True),
        "artifact_type": attr.string(
            default = "application/vnd.dev.cosign.simplesigning.v1+json",
        ),
        "_mkreferrer": attr.label(
            default = Label("//218_referrers:mkreferrer"),
            cfg = "exec",
            executable = True,
        ),
    },
)
