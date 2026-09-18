"""A rule whose actions can run on a persistent worker."""

def _worker_task_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".txt")

    args = ctx.actions.args()
    args.add("--output=" + out.path)
    args.add_all(ctx.attr.words, format_each = "--word=%s")

    # A worker MUST receive its arguments through a param file: the worker
    # protocol reserves the real command line for --persistent_worker.
    args.use_param_file("@%s", use_always = True)
    args.set_param_file_format("multiline")

    ctx.actions.run(
        outputs = [out],
        executable = ctx.executable._worker,
        arguments = [args],
        mnemonic = "WorkerTask",
        progress_message = "Worker task %s" % ctx.label,
        execution_requirements = {
            # This is what makes the action eligible for worker strategy.
            "supports-workers": "1",
            "requires-worker-protocol": "json",
        },
    )

    return [DefaultInfo(files = depset([out]))]

worker_task = rule(
    implementation = _worker_task_impl,
    attrs = {
        "words": attr.string_list(mandatory = True),
        "_worker": attr.label(
            default = Label("//147_persistent_workers:worker"),
            cfg = "exec",
            executable = True,
        ),
    },
)
