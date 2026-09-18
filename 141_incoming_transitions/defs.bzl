"""An incoming-edge transition: a rule that changes its OWN configuration."""

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")

def _force_release_impl(settings, attr):
    """A transition implementation returns the NEW setting values.

    settings: the current values of the flags listed in `inputs`
    attr:     the attributes of the target the transition applies to
    """
    _ = settings  # unused here, but available for conditional transitions
    return {
        "//141_incoming_transitions:channel": attr.channel,
        "//command_line_option:compilation_mode": "opt",
    }

_force_release = transition(
    implementation = _force_release_impl,
    # Flags the implementation READS.
    inputs = [],
    # Flags the implementation WRITES. Declaring an output it does not set,
    # or setting one it did not declare, is an error.
    outputs = [
        "//141_incoming_transitions:channel",
        "//command_line_option:compilation_mode",
    ],
)

def _release_artifact_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".txt")
    ctx.actions.write(
        output = out,
        content = "channel          = %s\ncompilation_mode = %s\n" % (
            ctx.attr._channel[BuildSettingInfo].value,
            ctx.var.get("COMPILATION_MODE", "?"),
        ),
    )
    return [DefaultInfo(files = depset([out]))]

release_artifact = rule(
    implementation = _release_artifact_impl,
    # cfg = <transition> on the RULE is an INCOMING EDGE transition: it changes
    # the configuration of this target and everything beneath it.
    cfg = _force_release,
    attrs = {
        "channel": attr.string(default = "stable"),
        "_channel": attr.label(
            default = Label("//141_incoming_transitions:channel"),
        ),
    },
)
