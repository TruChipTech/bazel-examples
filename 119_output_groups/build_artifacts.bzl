"""OutputGroupInfo: extra outputs consumers can request by name."""

def _artifact_impl(ctx):
    binary = ctx.actions.declare_file(ctx.label.name + ".bin")
    debug = ctx.actions.declare_file(ctx.label.name + ".debug")
    docs = ctx.actions.declare_file(ctx.label.name + ".md")
    coverage = ctx.actions.declare_file(ctx.label.name + ".lcov")

    ctx.actions.write(binary, "binary artifact for %s\n" % ctx.label.name)
    ctx.actions.write(debug, "debug symbols for %s\n" % ctx.label.name)
    ctx.actions.write(docs, "# %s\n\nGenerated documentation.\n" % ctx.label.name)
    ctx.actions.write(coverage, "TN:\nSF:%s\nend_of_record\n" % ctx.label.name)

    return [
        # DefaultInfo.files is what a plain `bazel build` produces. Keep it
        # small - just the primary artifact.
        DefaultInfo(files = depset([binary])),

        # OutputGroupInfo declares OPTIONAL extra outputs, built only when
        # someone asks for them with --output_groups.
        OutputGroupInfo(
            debug_symbols = depset([debug]),
            documentation = depset([docs]),
            coverage_data = depset([coverage]),
            # A group can contain several files, and files can be in several
            # groups.
            everything = depset([binary, debug, docs, coverage]),
        ),
    ]

build_artifacts = rule(
    implementation = _artifact_impl,
)
