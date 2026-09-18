"""Builds a release manifest that embeds stamped values."""

def _release_manifest_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".json")

    # STABLE_ keys live in ctx.info_file (stable-status.txt), NOT in
    # ctx.version_file - see sample 091 for why the names are misleading.
    args = ctx.actions.args()
    args.add(ctx.attr.app_name)
    args.add(ctx.info_file)
    args.add(out)

    ctx.actions.run_shell(
        inputs = [ctx.info_file],
        outputs = [out],
        arguments = [args],
        command = """
          app="$1"; status="$2"; out="$3"
          commit=$(grep '^STABLE_GIT_COMMIT ' "$status" | cut -d' ' -f2-)
          branch=$(grep '^STABLE_GIT_BRANCH ' "$status" | cut -d' ' -f2-)
          cat > "$out" <<JSON
{
  "app": "$app",
  "git_commit": "$commit",
  "git_branch": "$branch"
}
JSON
        """,
        mnemonic = "ReleaseManifest",
        progress_message = "Writing release manifest for %s" % ctx.label,
    )

    return [DefaultInfo(files = depset([out]))]

release_manifest = rule(
    implementation = _release_manifest_impl,
    attrs = {
        "app_name": attr.string(mandatory = True),
    },
)
