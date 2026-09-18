"""Building runfiles correctly in a custom rule."""

def _wrapper_impl(ctx):
    launcher = ctx.actions.declare_file(ctx.label.name + ".sh")

    ctx.actions.write(
        output = launcher,
        is_executable = True,
        content = """#!/usr/bin/env bash
set -euo pipefail
echo "wrapper: {name}"
echo "config : $(cat {config})"
exec "{inner}" "$@"
""".format(
            name = ctx.label.name,
            # short_path is the RUNFILES-relative path - correct for a script
            # that will run inside the runfiles tree.
            config = ctx.file.config.short_path,
            inner = ctx.executable.binary.short_path,
        ),
    )

    # Build the runfiles for THIS target:
    #   1. the files we directly need
    #   2. merged with every dependency's runfiles
    # Forgetting step 2 is the classic bug: the wrapper runs, but the wrapped
    # binary cannot find its own data.
    runfiles = ctx.runfiles(files = [ctx.file.config])
    runfiles = runfiles.merge(ctx.attr.binary[DefaultInfo].default_runfiles)

    return [
        DefaultInfo(
            executable = launcher,
            runfiles = runfiles,
        ),
    ]

wrapped_binary = rule(
    implementation = _wrapper_impl,
    executable = True,
    attrs = {
        "binary": attr.label(
            mandatory = True,
            executable = True,
            # cfg = "target": this binary is meant to RUN on the target
            # platform, so it is not an exec-configuration tool.
            cfg = "target",
        ),
        "config": attr.label(allow_single_file = True, mandatory = True),
    },
)
