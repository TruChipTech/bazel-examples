"""A module extension that generates a repository from MODULE.bazel data.

A module extension is how a module creates repositories. It runs during the
loading of MODULE.bazel, before any BUILD file is evaluated, and it is the only
place (besides use_repo_rule) that repository rules may be called.
"""

def _metadata_repo_impl(repository_ctx):
    """A repository rule: creates files for a brand new repository."""

    # Repository rules may read the environment, run programs, and download
    # files. Everything they produce must be written into the repo directory.
    repository_ctx.file(
        "BUILD.bazel",
        content = """
exports_files(["metadata.txt"])

filegroup(
    name = "metadata",
    srcs = ["metadata.txt"],
    visibility = ["//visibility:public"],
)
""",
    )

    repository_ctx.file(
        "metadata.txt",
        content = "channel: %s\nrecorded_by: %s\n" % (
            repository_ctx.attr.channel,
            repository_ctx.attr.recorded_by,
        ),
    )

metadata_repo = repository_rule(
    implementation = _metadata_repo_impl,
    attrs = {
        "channel": attr.string(mandatory = True),
        "recorded_by": attr.string(default = "unknown"),
    },
)

# --- The extension itself ----------------------------------------------------

def _build_metadata_impl(module_ctx):
    """Reads the tags every module declared, then creates repositories."""

    channel = "unset"
    recorded_by = "nobody"

    # module_ctx.modules is the list of modules that used this extension.
    # modules[0] is always the ROOT module when it used the extension.
    for module in module_ctx.modules:
        for record in module.tags.record:
            channel = record.channel
            recorded_by = module.name or "root"

    metadata_repo(
        name = "build_metadata_repo",
        channel = channel,
        recorded_by = recorded_by,
    )

# tag_class declares the schema of the "tags" callers may attach.
_record = tag_class(
    attrs = {
        "name": attr.string(mandatory = True),
        "channel": attr.string(default = "stable"),
    },
)

build_metadata = module_extension(
    implementation = _build_metadata_impl,
    tag_classes = {"record": _record},
)
