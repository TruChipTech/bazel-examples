"""A rule to be tested, plus a deliberately failing one."""

TagInfo = provider(fields = {"tag": "string", "count": "int"})

def _tagged_file_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".txt")

    if ctx.attr.count < 0:
        fail("count must not be negative, got %d" % ctx.attr.count)

    ctx.actions.write(
        output = out,
        content = "\n".join([ctx.attr.tag] * ctx.attr.count) + "\n",
    )

    return [
        DefaultInfo(files = depset([out])),
        TagInfo(tag = ctx.attr.tag, count = ctx.attr.count),
    ]

tagged_file = rule(
    implementation = _tagged_file_impl,
    attrs = {
        "tag": attr.string(mandatory = True),
        "count": attr.int(default = 1),
    },
)
