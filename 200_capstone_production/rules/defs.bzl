"""The capstone rule: generates a config header from a build setting."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load(":toolchain.bzl", "TOOLCHAIN_TYPE")

ConfigInfo = provider(
    doc = "Information about a generated configuration header.",
    fields = {
        "header": "File - the generated header",
        "entries": "int - number of config entries",
    },
)

def _generated_config_impl(ctx):
    toolchain = ctx.toolchains[TOOLCHAIN_TYPE]

    # The environment comes from a build setting, so one target produces
    # different output per --//...:environment value.
    environment = ctx.attr._environment[BuildSettingInfo].value

    entries = dict(ctx.attr.entries)
    entries["environment"] = environment
    entries["flavor"] = toolchain.flavor

    header = ctx.actions.declare_file(ctx.label.name + ".h")

    args = ctx.actions.args()
    args.add(header)
    args.add_all(["%s=%s" % (k, v) for k, v in sorted(entries.items())])
    args.use_param_file("@%s", use_always = False)
    args.set_param_file_format("multiline")

    ctx.actions.run(
        outputs = [header],
        executable = toolchain.generator,
        arguments = [args],
        mnemonic = "GenConfig",
        progress_message = "Generating config for %s (%s)" % (ctx.label, environment),
    )

    # A validation action: runs on every build, in parallel, without blocking.
    validation = ctx.actions.declare_file(ctx.label.name + ".validation")
    ctx.actions.run_shell(
        inputs = [header],
        outputs = [validation],
        arguments = [header.path, validation.path],
        command = """
          set -euo pipefail
          if grep -qiE '(password|secret|token)' "$1"; then
            echo "VALIDATION FAILED: generated config appears to contain a credential" >&2
            exit 1
          fi
          echo ok > "$2"
        """,
        mnemonic = "ValidateConfig",
    )

    return [
        DefaultInfo(files = depset([header])),
        ConfigInfo(header = header, entries = len(entries)),
        OutputGroupInfo(_validation = depset([validation])),
    ]

generated_config = rule(
    implementation = _generated_config_impl,
    attrs = {
        "entries": attr.string_dict(default = {}),
        "_environment": attr.label(
            default = Label("//200_capstone_production:environment"),
        ),
    },
    toolchains = [TOOLCHAIN_TYPE],
    doc = "Generates a C++ configuration header from build settings.",
)
