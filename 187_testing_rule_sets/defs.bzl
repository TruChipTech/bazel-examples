"""A small rule set, tested three different ways (see README.md)."""

ReportInfo = provider(fields = {"row_count": "int"})

def _csv_report_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".txt")

    ctx.actions.run_shell(
        inputs = [ctx.file.src],
        outputs = [out],
        arguments = [ctx.file.src.path, out.path, ctx.attr.title],
        command = """
          set -euo pipefail
          src="$1"; out="$2"; title="$3"
          rows=$(tail -n +2 "$src" | grep -c . || true)
          {
            echo "# $title"
            echo "rows: $rows"
            tail -n +2 "$src" | sort
          } > "$out"
        """,
        mnemonic = "CsvReport",
        progress_message = "Building report %s" % ctx.label,
    )

    return [
        DefaultInfo(files = depset([out])),
        ReportInfo(row_count = ctx.attr.expected_rows),
    ]

csv_report = rule(
    implementation = _csv_report_impl,
    attrs = {
        "src": attr.label(allow_single_file = [".csv"], mandatory = True),
        "title": attr.string(mandatory = True),
        "expected_rows": attr.int(default = 0),
    },
)
