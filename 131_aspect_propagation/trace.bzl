"""Controlling where an aspect propagates, and collecting results from all of it."""

TraceInfo = provider(fields = {"visited": "depset of string - labels visited"})

def _trace_impl(target, ctx):
    # Collect what the aspect recorded on each dependency it propagated to.
    transitive = []
    for attr_name in ctx.attr._follow:
        if hasattr(ctx.rule.attr, attr_name):
            value = getattr(ctx.rule.attr, attr_name)

            # A label attribute may be a single Target or a list of them.
            deps = value if type(value) == "list" else [value]
            for dep in deps:
                if type(dep) == "Target" and TraceInfo in dep:
                    transitive.append(dep[TraceInfo].visited)

    visited = depset(
        direct = ["%s (%s)" % (target.label, ctx.rule.kind)],
        transitive = transitive,
    )

    out = ctx.actions.declare_file("%s.trace" % target.label.name)
    ctx.actions.write(
        output = out,
        content = "\n".join(sorted(visited.to_list())) + "\n",
    )

    return [
        TraceInfo(visited = visited),
        OutputGroupInfo(trace = depset([out])),
    ]

trace_aspect = aspect(
    implementation = _trace_impl,
    attr_aspects = [
        "deps",
        "data",
    ],
    attrs = {
        # An aspect can have its OWN attributes. They must be private
        # (underscore-prefixed) with defaults, unless the aspect is used by a
        # rule that passes them explicitly.
        "_follow": attr.string_list(default = [
            "deps",
            "data",
        ]),
    },
)
