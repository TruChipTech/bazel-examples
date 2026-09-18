"""Custom providers: how rules pass typed data to each other."""

# provider() creates a new provider TYPE. `fields` documents and constrains it.
AssetInfo = provider(
    doc = "Information about a bundle of web assets.",
    fields = {
        "files": "depset of File - all assets in this bundle and its deps",
        "kind": "string - 'css', 'js' or 'mixed'",
        "entry_point": "File or None - the main entry file",
    },
)

def _asset_library_impl(ctx):
    direct = ctx.files.srcs

    # Collect providers from dependencies. Indexing a Target with a provider
    # type returns that provider, or fails if the target does not have it.
    transitive = [dep[AssetInfo].files for dep in ctx.attr.deps]

    kinds = {}
    for f in direct:
        kinds[f.extension] = True
    kind = "mixed" if len(kinds) > 1 else (direct[0].extension if direct else "none")

    return [
        # Return BOTH: DefaultInfo for generic consumers (bazel build, srcs),
        # and the custom provider for rules that understand it.
        DefaultInfo(files = depset(direct, transitive = transitive)),
        AssetInfo(
            files = depset(direct, transitive = transitive),
            kind = kind,
            entry_point = ctx.file.entry_point,
        ),
    ]

asset_library = rule(
    implementation = _asset_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "entry_point": attr.label(allow_single_file = True),
        # providers = [AssetInfo] makes the requirement explicit: a dependency
        # that is not an asset_library is rejected with a clear message.
        "deps": attr.label_list(providers = [AssetInfo]),
    },
)

def _asset_bundle_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".bundle")

    info = ctx.attr.library[AssetInfo]
    all_files = info.files.to_list()

    lines = [
        "kind: %s" % info.kind,
        "entry: %s" % (info.entry_point.basename if info.entry_point else "none"),
        "file count: %d" % len(all_files),
    ] + ["  %s" % f.basename for f in sorted(all_files, key = lambda f: f.basename)]

    ctx.actions.write(output = out, content = "\n".join(lines) + "\n")
    return [DefaultInfo(files = depset([out]))]

asset_bundle = rule(
    implementation = _asset_bundle_impl,
    attrs = {
        "library": attr.label(providers = [AssetInfo], mandatory = True),
    },
)
