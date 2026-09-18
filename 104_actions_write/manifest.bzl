"""ctx.actions.write - creating files without running a process."""

def _manifest_impl(ctx):
    # declare_file creates a File object in this target's output directory.
    # The name is relative to the package, so two targets in the same package
    # must not declare the same filename.
    out = ctx.actions.declare_file(ctx.label.name + ".manifest")

    entries = []
    for f in ctx.files.srcs:
        # short_path is the runfiles-relative path (what a program would use).
        # path is the execroot-relative path (what an action would use).
        entries.append("%s\t%s" % (f.short_path, f.extension))

    ctx.actions.write(
        output = out,
        content = "\n".join(sorted(entries)) + "\n",
        # is_executable = True would chmod +x the result.
        is_executable = False,
    )

    return [DefaultInfo(files = depset([out]))]

manifest = rule(
    implementation = _manifest_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True, mandatory = True),
    },
)

def _script_impl(ctx):
    """ctx.actions.write can also produce an executable script."""
    script = ctx.actions.declare_file(ctx.label.name + ".sh")

    ctx.actions.write(
        output = script,
        content = """#!/usr/bin/env bash
echo "generated script for {label}"
echo "message: {message}"
""".format(label = ctx.label, message = ctx.attr.message),
        is_executable = True,
    )

    # executable = script makes this target runnable with `bazel run`.
    return [DefaultInfo(executable = script)]

generated_script = rule(
    implementation = _script_impl,
    attrs = {"message": attr.string(default = "hello")},
    executable = True,
)
