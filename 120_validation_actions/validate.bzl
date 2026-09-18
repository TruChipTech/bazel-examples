"""Validation actions: checks that run automatically, without blocking."""

def _checked_config_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".conf")

    ctx.actions.run_shell(
        inputs = [ctx.file.src],
        outputs = [out],
        arguments = [ctx.file.src.path, out.path],
        command = 'cp "$1" "$2"',
        mnemonic = "CopyConfig",
    )

    # A VALIDATION output: its only purpose is to exist if the check passed.
    validation = ctx.actions.declare_file(ctx.label.name + ".validation")

    ctx.actions.run_shell(
        inputs = [ctx.file.src],
        outputs = [validation],
        arguments = [ctx.file.src.path, validation.path],
        command = """
          set -euo pipefail
          if grep -qE '(password|secret|api_key)\\s*[:=]' "$1"; then
            echo "VALIDATION FAILED: $1 appears to contain a hardcoded secret" >&2
            exit 1
          fi
          echo "ok" > "$2"
        """,
        mnemonic = "ValidateConfig",
        progress_message = "Validating %s" % ctx.label,
    )

    return [
        DefaultInfo(files = depset([out])),
        # The "_validation" output group is SPECIAL: Bazel builds it for every
        # requested target automatically, without it being a dependency of
        # anything. So the check runs, but it does not block the real output.
        OutputGroupInfo(_validation = depset([validation])),
    ]

checked_config = rule(
    implementation = _checked_config_impl,
    attrs = {
        "src": attr.label(allow_single_file = True, mandatory = True),
    },
)
