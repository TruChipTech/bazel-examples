"""A rule with several attribute kinds, showing how each is read."""

def _report_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".txt")

    lines = [
        "title      : %s" % ctx.attr.title,
        "max_items  : %d" % ctx.attr.max_items,
        "verbose    : %s" % ctx.attr.verbose,
        "categories : %s" % ", ".join(ctx.attr.categories),
        "owner map  : %s" % str(sorted(ctx.attr.owners.items())),
    ]

    # ctx.files.<name> turns a label_list into a list of File objects.
    lines.append("data files : %d" % len(ctx.files.data))
    for f in ctx.files.data:
        lines.append("  - %s" % f.short_path)

    # ctx.file.<name> (singular) is for allow_single_file attributes.
    if ctx.file.header:
        lines.append("header     : %s" % ctx.file.header.short_path)

    ctx.actions.write(output = out, content = "\n".join(lines) + "\n")
    return [DefaultInfo(files = depset([out]))]

report = rule(
    implementation = _report_impl,
    attrs = {
        # --- scalar attributes ---
        "title": attr.string(mandatory = True),
        "max_items": attr.int(default = 10),
        "verbose": attr.bool(default = False),

        # --- collections ---
        "categories": attr.string_list(default = []),
        "owners": attr.string_dict(default = {}),

        # --- labels: these create DEPENDENCY EDGES in the graph ---
        "data": attr.label_list(
            allow_files = True,
            doc = "Files to describe.",
        ),
        "header": attr.label(
            allow_single_file = [".txt"],
            doc = "Optional single header file.",
        ),
    },
)
