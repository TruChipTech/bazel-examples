"""A practical linting aspect."""

LintInfo = provider(fields = {"reports": "depset of File"})

def _lint_aspect_impl(target, ctx):
    reports = []

    for src in getattr(ctx.rule.attr, "srcs", []):
        for f in src.files.to_list():
            if f.extension != "py":
                continue
            report = ctx.actions.declare_file("%s.%s.lint" % (target.label.name, f.basename))
            ctx.actions.run(
                inputs = [f],
                outputs = [report],
                # The linter is an implicit dependency of the ASPECT.
                executable = ctx.executable._linter,
                arguments = [f.path, report.path],
                mnemonic = "PyLint",
                progress_message = "Linting %s" % f.short_path,
            )
            reports.append(report)

    transitive = [
        dep[LintInfo].reports
        for dep in getattr(ctx.rule.attr, "deps", [])
        if LintInfo in dep
    ]

    all_reports = depset(direct = reports, transitive = transitive)

    return [
        LintInfo(reports = all_reports),
        OutputGroupInfo(lint = all_reports),
    ]

lint_aspect = aspect(
    implementation = _lint_aspect_impl,
    attr_aspects = ["deps"],
    attrs = {
        "_linter": attr.label(
            default = Label("//134_aspect_linting:lint"),
            cfg = "exec",
            executable = True,
        ),
    },
)

def _lint_report_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".summary")

    reports = depset(transitive = [
        t[LintInfo].reports
        for t in ctx.attr.targets
    ]).to_list()

    ctx.actions.run_shell(
        inputs = reports,
        outputs = [out],
        arguments = [out.path] + [r.path for r in reports],
        command = """
          set -euo pipefail
          out="$1"; shift
          : > "$out"
          for r in "$@"; do cat "$r" >> "$out"; done
          issues=$(grep -cv ': clean$' "$out" || true)
          echo "--- $issues finding(s) ---" >> "$out"
        """,
        mnemonic = "LintSummary",
        progress_message = "Summarizing lint for %s" % ctx.label,
    )

    return [DefaultInfo(files = depset([out]))]

lint_report = rule(
    implementation = _lint_report_impl,
    attrs = {
        "targets": attr.label_list(aspects = [lint_aspect], mandatory = True),
    },
)
