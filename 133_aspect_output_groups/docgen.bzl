"""Aggregating output groups across an aspect's traversal."""

DocsInfo = provider(fields = {"docs": "depset of File"})

def _docgen_aspect_impl(target, ctx):
    own_docs = []

    if hasattr(ctx.rule.attr, "srcs"):
        for src in ctx.rule.attr.srcs:
            for f in src.files.to_list():
                if f.extension != "py":
                    continue
                doc = ctx.actions.declare_file("%s.%s.doc" % (target.label.name, f.basename))
                ctx.actions.run_shell(
                    inputs = [f],
                    outputs = [doc],
                    arguments = [f.path, doc.path, f.short_path],
                    command = """
                      set -euo pipefail
                      {
                        echo "# $3"
                        grep -E '^(def |class )' "$1" || echo "(no top-level definitions)"
                      } > "$2"
                    """,
                    mnemonic = "GenDoc",
                    progress_message = "Documenting %s" % f.short_path,
                )
                own_docs.append(doc)

    # Aggregate the dependencies' docs so the TOP-LEVEL target's output group
    # contains everything, not just its own files. Without this, sample 130's
    # limitation applies: only the requested target's files are collected.
    transitive = [
        dep[DocsInfo].docs
        for dep in getattr(ctx.rule.attr, "deps", [])
        if DocsInfo in dep
    ]

    all_docs = depset(direct = own_docs, transitive = transitive)

    return [
        DocsInfo(docs = all_docs),
        OutputGroupInfo(docs = all_docs),
    ]

docgen_aspect = aspect(
    implementation = _docgen_aspect_impl,
    attr_aspects = ["deps"],
)
