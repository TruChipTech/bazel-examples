"""oci_artifact: store arbitrary content in an OCI layout.

Like sample 201, this must be a rule rather than a genrule: the output is a
DIRECTORY, and a genrule cannot declare one.
"""

def _oci_artifact_impl(ctx):
    out = ctx.actions.declare_directory(ctx.label.name + "_layout")
    ctx.actions.run(
        inputs = [ctx.file.payload],
        outputs = [out],
        executable = ctx.executable._mkartifact,
        arguments = [out.path, ctx.attr.artifact_type, ctx.file.payload.path, ctx.attr.ref],
        mnemonic = "OciArtifact",
        progress_message = "Packing %s as an OCI artifact" % ctx.label,
    )
    return [DefaultInfo(files = depset([out]))]

oci_artifact = rule(
    implementation = _oci_artifact_impl,
    attrs = {
        "payload": attr.label(allow_single_file = True, mandatory = True),
        "artifact_type": attr.string(mandatory = True),
        "ref": attr.string(default = "latest"),
        "_mkartifact": attr.label(
            default = Label("//217_oci_artifacts:mkartifact"),
            cfg = "exec",
            executable = True,
        ),
    },
)
