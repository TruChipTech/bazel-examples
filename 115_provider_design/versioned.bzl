"""Provider design: init callbacks, validation, and evolution."""

def _version_info_init(*, major, minor, patch = 0, label = None):
    """An init callback runs when the provider is CONSTRUCTED.

    It can validate, normalize and compute derived fields, so every consumer
    sees a well-formed value. Without it, each producer would have to remember
    to build the provider correctly.
    """
    if major < 0 or minor < 0 or patch < 0:
        fail("version components must be non-negative")
    if major == 0 and minor == 0 and patch == 0:
        fail("version 0.0.0 is not allowed")

    return {
        "major": major,
        "minor": minor,
        "patch": patch,
        "label": label,
        # A derived field, computed once rather than in every consumer.
        "string": "%d.%d.%d" % (major, minor, patch),
    }

# The two-value form: the second return value is the RAW constructor, which
# bypasses the init callback. Keep it private so only this file can use it.
VersionInfo, _new_version_info = provider(
    doc = "A semantic version.",
    fields = {
        "major": "int",
        "minor": "int",
        "patch": "int",
        "label": "optional string qualifier",
        "string": "derived 'major.minor.patch' string",
    },
    init = _version_info_init,
)

def _versioned_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".version")

    version = VersionInfo(
        major = ctx.attr.major,
        minor = ctx.attr.minor,
        patch = ctx.attr.patch,
        label = ctx.attr.qualifier or None,
    )

    text = version.string
    if version.label:
        text += "-" + version.label

    ctx.actions.write(output = out, content = text + "\n")
    return [
        DefaultInfo(files = depset([out])),
        version,
    ]

versioned = rule(
    implementation = _versioned_impl,
    attrs = {
        "major": attr.int(mandatory = True),
        "minor": attr.int(mandatory = True),
        "patch": attr.int(default = 0),
        "qualifier": attr.string(default = ""),
    },
)

def _requires_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".check")
    dep = ctx.attr.dependency[VersionInfo]

    ok = (dep.major > ctx.attr.min_major) or \
         (dep.major == ctx.attr.min_major and dep.minor >= ctx.attr.min_minor)

    ctx.actions.write(
        output = out,
        content = "dependency %s, required >= %d.%d, satisfied: %s\n" % (
            dep.string,
            ctx.attr.min_major,
            ctx.attr.min_minor,
            ok,
        ),
    )
    return [DefaultInfo(files = depset([out]))]

requires_version = rule(
    implementation = _requires_impl,
    attrs = {
        "dependency": attr.label(providers = [VersionInfo], mandatory = True),
        "min_major": attr.int(mandatory = True),
        "min_minor": attr.int(default = 0),
    },
)
