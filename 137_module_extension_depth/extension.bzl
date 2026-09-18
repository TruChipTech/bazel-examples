"""A module extension that AGGREGATES declarations from every module."""

def _registry_repo_impl(repository_ctx):
    rows = repository_ctx.attr.rows

    repository_ctx.file(
        "components.bzl",
        content = "COMPONENTS = %s\n" % repr(
            [r.split("=", 1) for r in rows],
        ),
    )

    repository_ctx.file(
        "registry.txt",
        content = "\n".join(sorted(rows)) + "\n",
    )

    repository_ctx.file(
        "BUILD.bazel",
        content = '''
exports_files(["components.bzl"])

filegroup(
    name = "registry",
    srcs = ["registry.txt"],
    visibility = ["//visibility:public"],
)
''',
    )

_registry_repo = repository_rule(
    implementation = _registry_repo_impl,
    attrs = {"rows": attr.string_list()},
)

def _registry_impl(module_ctx):
    """Runs ONCE, seeing the tags from EVERY module that used this extension.

    That global view is the whole reason module extensions exist. Five modules
    each asking for a Python package must produce ONE consistent resolution,
    not five conflicting repositories.
    """
    rows = []
    seen = {}

    for module in module_ctx.modules:
        for component in module.tags.component:
            # module.is_root tells you whether this came from the root module,
            # which is how extensions let the root override its dependencies.
            source = "root" if module.is_root else (module.name or "unknown")

            if component.name in seen:
                # Conflict resolution is the extension's job.
                fail("component '%s' declared twice (by %s and %s)" % (
                    component.name,
                    seen[component.name],
                    source,
                ))
            seen[component.name] = source
            rows.append("%s=%s:%s" % (component.name, component.owner, source))

    _registry_repo(name = "component_registry", rows = rows)

    # Returning extension metadata tells Bazel whether the result is
    # reproducible, and enables `bazel mod tidy` to fix use_repo calls.
    return module_ctx.extension_metadata(
        root_module_direct_deps = ["component_registry"],
        root_module_direct_dev_deps = [],
        reproducible = True,
    )

_component = tag_class(
    attrs = {
        "name": attr.string(mandatory = True, doc = "Component identifier."),
        "owner": attr.string(mandatory = True, doc = "Owning team."),
    },
    doc = "Registers one component in the shared registry.",
)

registry = module_extension(
    implementation = _registry_impl,
    tag_classes = {"component": _component},
    doc = "Builds a repo-wide component registry from every module's tags.",
)
