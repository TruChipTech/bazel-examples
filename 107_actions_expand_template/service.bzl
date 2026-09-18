"""ctx.actions.expand_template - substitution inside a rule."""

def _service_module_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".py")

    # Substitutions are computed in Starlark, so they can be derived from
    # attributes, deps, or the configuration - which a static template file
    # in a genrule cannot do.
    endpoints_literal = "[%s]" % ", ".join([
        '"%s"' % e
        for e in ctx.attr.endpoints
    ])

    ctx.actions.expand_template(
        template = ctx.file.template,
        output = out,
        substitutions = {
            "%{NAME}": ctx.attr.service_name,
            "%{PORT}": str(ctx.attr.port),
            "%{ENDPOINTS}": endpoints_literal,
        },
        is_executable = False,
    )

    return [DefaultInfo(files = depset([out]))]

service_module = rule(
    implementation = _service_module_impl,
    attrs = {
        "template": attr.label(allow_single_file = True, mandatory = True),
        "service_name": attr.string(mandatory = True),
        "port": attr.int(default = 8080),
        "endpoints": attr.string_list(default = []),
    },
)
