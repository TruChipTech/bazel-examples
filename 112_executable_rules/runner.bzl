"""Making a rule runnable with `bazel run`."""

def _task_runner_impl(ctx):
    script = ctx.actions.declare_file(ctx.label.name + "_run.sh")

    steps = "\n".join([
        'echo "  [%d/%d] %s"' % (i + 1, len(ctx.attr.steps), step)
        for i, step in enumerate(ctx.attr.steps)
    ])

    ctx.actions.write(
        output = script,
        is_executable = True,
        content = """#!/usr/bin/env bash
set -euo pipefail
echo "running task: {name}"
{steps}
echo "done. extra args: $*"
""".format(name = ctx.attr.task_name, steps = steps),
    )

    return [
        DefaultInfo(
            # BOTH of these are required for `bazel run` to work:
            #   1. executable = <File> here
            #   2. executable = True on the rule() below
            executable = script,
            runfiles = ctx.runfiles(files = ctx.files.data),
        ),
    ]

task_runner = rule(
    implementation = _task_runner_impl,
    executable = True,
    attrs = {
        "task_name": attr.string(mandatory = True),
        "steps": attr.string_list(default = []),
        "data": attr.label_list(allow_files = True),
    },
)
