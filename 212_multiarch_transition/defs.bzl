"""Build ONE target for N architectures with a split transition.

Sample 205 listed each architecture's image by hand. That does not scale and it
lets the per-arch definitions drift. A split transition builds the SAME target
graph once per platform, so there is exactly one definition.
"""

load("//201_oci_layout_basics:oci.bzl", "OciImageInfo")

def _multiarch_transition_impl(settings, attr):
    _ = settings
    # Returning a dict-of-dicts keyed by platform name: Bazel builds the
    # dependency once per key, each in its own configuration.
    return {
        platform: {"//command_line_option:platforms": str(platform_label)}
        for platform, platform_label in attr.platforms.items()
    }

_multiarch_transition = transition(
    implementation = _multiarch_transition_impl,
    inputs = [],
    outputs = ["//command_line_option:platforms"],
)

def _multiarch_images_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + "_manifest.txt")

    lines = []
    inputs = []
    # ctx.split_attr.<attr> is a dict keyed by the transition's keys.
    #
    # GOTCHA: the VALUE type follows the attribute type, not the transition:
    #   attr.label      + split -> dict[key] = Target        (a single target)
    #   attr.label_list + split -> dict[key] = [Target, ...] (a list)
    # Iterating a Target fails with "type 'Target' is not iterable".
    for key, target in ctx.split_attr.image.items():
        layout = target[OciImageInfo].layout
        inputs.append(layout)
        lines.append("%s\t%s" % (key, layout.path))

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = [out],
        arguments = [out.path] + [l for pair in lines for l in pair.split("\t")],
        command = """
          set -euo pipefail
          out="$1"; shift
          : > "$out"
          while [ "$#" -gt 0 ]; do
            platform="$1"; layout="$2"; shift 2
            printf '%s %s\\n' "$platform" "$(cat "$layout/digest.txt")" >> "$out"
          done
          sort -o "$out" "$out"
        """,
        mnemonic = "MultiArchManifest",
        progress_message = "Collecting per-platform digests for %s" % ctx.label,
    )

    return [DefaultInfo(files = depset([out] + inputs))]

multiarch_images = rule(
    implementation = _multiarch_images_impl,
    attrs = {
        "image": attr.label(
            providers = [OciImageInfo],
            mandatory = True,
            cfg = _multiarch_transition,
        ),
        "platforms": attr.string_keyed_label_dict(mandatory = True),
    },
)
