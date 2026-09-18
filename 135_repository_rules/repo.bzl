"""Repository rules: creating external repositories from scratch.

A repository rule runs during the LOADING phase, BEFORE any BUILD file is
evaluated. Unlike a normal rule it CAN touch the outside world: read the
environment, run programs, download files, inspect the filesystem.

That power comes with a responsibility: the result is cached per repository,
so a repository rule must be deterministic given its declared inputs, or the
build stops being reproducible.
"""

def _host_info_repo_impl(repository_ctx):
    lines = []

    # repository_ctx.os exposes host information.
    lines.append('OS_NAME = "%s"' % repository_ctx.os.name)
    lines.append('ARCH = "%s"' % repository_ctx.os.arch)

    # getenv() declares a dependency on the variable: if it changes, Bazel
    # REFETCHES this repository. Reading os.environ directly does not.
    probed = {}
    for var in repository_ctx.attr.probe_vars:
        value = repository_ctx.getenv(var, "")
        probed[var] = "set" if value else "unset"
    lines.append("PROBED = %s" % repr(probed))

    # Files are written into the new repository's root.
    repository_ctx.file("host_info.bzl", content = "\n".join(lines) + "\n")

    repository_ctx.file(
        "BUILD.bazel",
        content = '''
exports_files(["host_info.bzl", "summary.txt"])

filegroup(
    name = "summary",
    srcs = ["summary.txt"],
    visibility = ["//visibility:public"],
)
''',
    )

    repository_ctx.file(
        "summary.txt",
        content = "host: %s/%s\nprobed: %s\n" % (
            repository_ctx.os.name,
            repository_ctx.os.arch,
            ", ".join(sorted(probed.keys())),
        ),
    )

host_info_repo = repository_rule(
    implementation = _host_info_repo_impl,
    attrs = {
        "probe_vars": attr.string_list(default = []),
    },
    # environ lists variables that invalidate this repository when they change.
    environ = ["HOME"],
    # local = True means "re-run on every build" - correct for rules that
    # inspect the machine. Omit it for rules that fetch immutable content.
    local = True,
    doc = "Generates a repository describing the host machine.",
)
