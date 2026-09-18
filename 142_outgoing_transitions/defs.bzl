"""Outgoing-edge and split transitions: changing configuration for DEPENDENCIES."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

# --- A 1:1 outgoing transition ----------------------------------------------

def _debug_dep_impl(settings, attr):
    _ = (settings, attr)
    return {"//command_line_option:compilation_mode": "dbg"}

_debug_dep = transition(
    implementation = _debug_dep_impl,
    inputs = [],
    outputs = ["//command_line_option:compilation_mode"],
)

# --- A SPLIT transition: one dependency built SEVERAL ways -------------------

def _multi_channel_impl(settings, attr):
    _ = (settings, attr)
    # Returning a DICT of dicts means: build the dependency once per key.
    return {
        "alpha": {"//142_outgoing_transitions:channel": "alpha"},
        "beta": {"//142_outgoing_transitions:channel": "beta"},
        "stable": {"//142_outgoing_transitions:channel": "stable"},
    }

_multi_channel = transition(
    implementation = _multi_channel_impl,
    inputs = [],
    outputs = ["//142_outgoing_transitions:channel"],
)

def _channel_probe_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".txt")
    ctx.actions.write(
        output = out,
        content = "channel=%s mode=%s\n" % (
            ctx.attr._channel[BuildSettingInfo].value,
            ctx.var.get("COMPILATION_MODE", "?"),
        ),
    )
    return [DefaultInfo(files = depset([out]))]

channel_probe = rule(
    implementation = _channel_probe_impl,
    attrs = {
        "_channel": attr.label(
            default = Label("//142_outgoing_transitions:channel"),
        ),
    },
)

def _bundle_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".bundle")

    # With a SPLIT transition, the attribute becomes a DICT keyed by the
    # transition's keys, each holding the list of configured targets.
    inputs = []
    parts = []
    for key, targets in ctx.split_attr.variants.items():
        for t in targets:
            for f in t[DefaultInfo].files.to_list():
                inputs.append(f)
                parts.append("%s -> %s" % (key, f.path))

    # GOTCHA: an attr.label carrying a `cfg` transition arrives as a LIST,
    # not a single Target - because Bazel cannot know at schema time whether
    # the transition is 1:1 or a split. Index [0] for a 1:1 transition.
    for t in ctx.attr.debug_variant:
        inputs.extend(t[DefaultInfo].files.to_list())

    ctx.actions.run_shell(
        inputs = inputs,
        outputs = [out],
        arguments = [out.path] + [f.path for f in inputs],
        command = """
          set -euo pipefail
          out="$1"; shift
          : > "$out"
          for f in "$@"; do
            echo "--- $f" >> "$out"
            cat "$f" >> "$out"
          done
        """,
        mnemonic = "Bundle",
    )

    return [DefaultInfo(files = depset([out]))]

multi_bundle = rule(
    implementation = _bundle_impl,
    attrs = {
        # cfg = <split transition> on an ATTRIBUTE: the dependency is built
        # once per transition key.
        "variants": attr.label_list(cfg = _multi_channel, mandatory = True),
        # cfg = <1:1 transition>: the dependency is built in a changed config.
        "debug_variant": attr.label(cfg = _debug_dep, mandatory = True),
    },
)
