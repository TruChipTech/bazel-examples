"""depset: the data structure for transitive dependency information."""

CollectInfo = provider(fields = {"transitive_files": "depset of File"})

def _node_impl(ctx):
    # THE PATTERN. Memorize this shape - it appears in every rule set.
    #
    #   depset(direct = <this target's own items>,
    #          transitive = [<each dependency's depset>])
    #
    # It is O(1): nothing is copied or merged. The depset is a NODE pointing at
    # its children, and flattening happens only if someone calls to_list().
    deps_depsets = [dep[CollectInfo].transitive_files for dep in ctx.attr.deps]

    files = depset(
        direct = ctx.files.srcs,
        transitive = deps_depsets,
    )

    out = ctx.actions.declare_file(ctx.label.name + ".txt")

    # to_list() FLATTENS the depset. It is O(n) and allocates - call it once,
    # as late as possible, and never inside a loop.
    names = sorted([f.basename for f in files.to_list()])

    ctx.actions.write(
        output = out,
        content = "%s sees %d file(s):\n%s\n" % (
            ctx.label.name,
            len(names),
            "\n".join(["  " + n for n in names]),
        ),
    )

    return [
        DefaultInfo(files = depset([out])),
        CollectInfo(transitive_files = files),
    ]

collect_node = rule(
    implementation = _node_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(providers = [CollectInfo]),
    },
)
