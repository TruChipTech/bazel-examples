"""Applying an aspect from a RULE instead of the command line."""

SizeInfo = provider(fields = {"entries": "depset of string"})

def _size_aspect_impl(target, ctx):
    entries = []
    if hasattr(ctx.rule.attr, "srcs"):
        for src in ctx.rule.attr.srcs:
            for f in src.files.to_list():
                entries.append("%s\t%s" % (f.short_path, ctx.rule.kind))

    transitive = []
    if hasattr(ctx.rule.attr, "deps"):
        for dep in ctx.rule.attr.deps:
            if SizeInfo in dep:
                transitive.append(dep[SizeInfo].entries)

    return [SizeInfo(entries = depset(direct = entries, transitive = transitive))]

size_aspect = aspect(
    implementation = _size_aspect_impl,
    attr_aspects = ["deps"],
    # An aspect applied by a rule CAN have public parameters, supplied by the
    # rule that applies it. They must be attr.string with `values`.
    attrs = {
        "detail": attr.string(
            default = "short",
            values = [
                "full",
                "short",
            ],
        ),
    },
)

def _report_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".report")

    all_entries = depset(transitive = [
        dep[SizeInfo].entries
        for dep in ctx.attr.targets
    ]).to_list()

    lines = ["source inventory (%d files)" % len(all_entries), ""]
    lines += sorted(all_entries)

    ctx.actions.write(output = out, content = "\n".join(lines) + "\n")
    return [DefaultInfo(files = depset([out]))]

inventory_report = rule(
    implementation = _report_impl,
    attrs = {
        # aspects = [...] on a label_list applies the aspect to everything
        # listed, and to everything the aspect propagates to from there.
        "targets": attr.label_list(aspects = [size_aspect], mandatory = True),
    },
)
