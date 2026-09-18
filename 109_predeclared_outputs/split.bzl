"""Predeclared outputs: outputs that have their own labels."""

def _split_impl(ctx):
    # ctx.outputs.<name> gives the File for an attr.output attribute. The
    # caller chose the filename in the BUILD file, so it has a real label and
    # other targets can depend on it INDIVIDUALLY.
    ctx.actions.run_shell(
        inputs = [ctx.file.src],
        outputs = [
            ctx.outputs.head_out,
            ctx.outputs.tail_out,
        ],
        arguments = [
            ctx.file.src.path,
            ctx.outputs.head_out.path,
            ctx.outputs.tail_out.path,
            str(ctx.attr.head_lines),
        ],
        command = """
          set -euo pipefail
          head -n "$4" "$1" > "$2"
          tail -n +$(( $4 + 1 )) "$1" > "$3"
        """,
        mnemonic = "SplitFile",
        progress_message = "Splitting %s" % ctx.label,
    )

    return [DefaultInfo(files = depset([
        ctx.outputs.head_out,
        ctx.outputs.tail_out,
    ]))]

split_file = rule(
    implementation = _split_impl,
    attrs = {
        "src": attr.label(allow_single_file = True, mandatory = True),
        "head_lines": attr.int(default = 3),
        # attr.output: the CALLER supplies the output filename, and that file
        # becomes an addressable target.
        "head_out": attr.output(mandatory = True),
        "tail_out": attr.output(mandatory = True),
    },
)

# --- The other form: implicit outputs derived from the target name -----------

def _report_impl(ctx):
    # ctx.outputs.<key> is populated from the rule's `outputs` dict below.
    ctx.actions.write(
        output = ctx.outputs.summary,
        content = "summary for %s\n" % ctx.label.name,
    )
    return [DefaultInfo(files = depset([ctx.outputs.summary]))]

named_report = rule(
    implementation = _report_impl,
    # %{name} is substituted with the target's name. The resulting file is
    # addressable as //pkg:<name>_summary.txt without the caller naming it.
    outputs = {"summary": "%{name}_summary.txt"},
)
