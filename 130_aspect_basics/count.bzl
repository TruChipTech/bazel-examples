"""Aspects: attaching extra analysis to an existing dependency graph."""

FileCountInfo = provider(fields = {
    "count": "int - files in this target",
    "transitive_count": "int - files in this target and all its deps",
})

def _count_aspect_impl(target, ctx):
    """An aspect implementation takes TWO parameters.

    target : the Target the aspect is visiting
    ctx    : like a rule ctx, but ctx.rule.attr holds the VISITED rule's
             attributes (not the aspect's own).
    """

    # Count this target's own sources. Not every rule has `srcs`, so guard.
    own = 0
    if hasattr(ctx.rule.attr, "srcs"):
        for src in ctx.rule.attr.srcs:
            own += len(src.files.to_list())

    # Sum what the aspect already computed for the dependencies. Bazel has
    # already run the aspect on them, because it propagates along `deps`.
    transitive = own
    if hasattr(ctx.rule.attr, "deps"):
        for dep in ctx.rule.attr.deps:
            if FileCountInfo in dep:
                transitive += dep[FileCountInfo].transitive_count

    # Write a per-target report.
    out = ctx.actions.declare_file("%s.filecount" % target.label.name)
    ctx.actions.write(
        output = out,
        content = "%s: %d own, %d transitive\n" % (target.label, own, transitive),
    )

    return [
        FileCountInfo(count = own, transitive_count = transitive),
        # An aspect can add output groups to the target it visits.
        OutputGroupInfo(file_count = depset([out])),
    ]

file_count_aspect = aspect(
    implementation = _count_aspect_impl,
    # attr_aspects names the attributes to PROPAGATE along. ["deps"] means
    # "visit everything reachable through deps". ["*"] means every attribute.
    attr_aspects = ["deps"],
)
