"""ctx.actions.run_shell - when you genuinely need a shell."""

def _pipeline_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".txt")

    # run_shell is for genuine shell work: pipes, redirection, chained
    # commands. Everything inside `command` is a bash script.
    #
    # Positional arguments arrive as $1, $2, ... (there is no $0 script name).
    ctx.actions.run_shell(
        inputs = ctx.files.srcs,
        outputs = [out],
        arguments = [
            f.path
            for f in ctx.files.srcs
        ] + [out.path],
        command = """
          set -euo pipefail
          # All but the last argument are inputs; the last is the output.
          args=("$@")
          out="${args[${#args[@]}-1]}"
          unset 'args[${#args[@]}-1]'

          cat "${args[@]}" \
            | tr '[:upper:]' '[:lower:]' \
            | tr -cs '[:alnum:]' '\\n' \
            | grep -v '^$' \
            | sort \
            | uniq -c \
            | sort -rn \
            | head -n 5 \
            > "$out"
        """,
        mnemonic = "TopWords",
        progress_message = "Computing top words for %s" % ctx.label,
    )

    return [DefaultInfo(files = depset([out]))]

top_words = rule(
    implementation = _pipeline_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True, mandatory = True),
    },
)
