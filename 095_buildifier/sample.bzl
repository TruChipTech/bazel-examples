"""A small, correctly-formatted .bzl file for buildifier_test to check."""

DEFAULT_TAGS = [
    "managed",
    "sample",
]

def tagged_name(name, suffix = "lib"):
    """Returns a conventional target name.

    Args:
      name: base name.
      suffix: appended after an underscore.

    Returns:
      A string target name.
    """
    return "%s_%s" % (name, suffix)
