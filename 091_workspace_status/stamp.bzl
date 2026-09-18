"""Reading workspace status (stamping) information in a rule."""

def _stamped_file_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".txt")

    # Bazel exposes two status files, and the names are easy to get backwards:
    #
    #   ctx.info_file    -> stable-status.txt
    #                       Holds keys prefixed STABLE_. Changing one DOES
    #                       invalidate downstream actions.
    #
    #   ctx.version_file -> volatile-status.txt
    #                       Holds everything else (timestamps etc). Changing a
    #                       value here does NOT trigger a rebuild.
    #
    # Actions that consume these must declare them as inputs.
    ctx.actions.run_shell(
        inputs = [ctx.info_file, ctx.version_file],
        outputs = [out],
        command = """
          {
            echo "=== ctx.info_file (stable-status.txt) ==="
            cat "$1"
            echo "=== ctx.version_file (volatile-status.txt) ==="
            cat "$2"
          } > "$3"
        """,
        arguments = [ctx.info_file.path, ctx.version_file.path, out.path],
        mnemonic = "Stamp",
        progress_message = "Stamping %s" % ctx.label,
    )

    return [DefaultInfo(files = depset([out]))]

stamped_file = rule(
    implementation = _stamped_file_impl,
)
