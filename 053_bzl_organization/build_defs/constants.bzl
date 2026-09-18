"""Shared constants. Values only - no rule calls."""

# Public: no leading underscore.
DEFAULT_COPTS = [
    "-Wall",
    "-Wextra",
]

SUPPORTED_PLATFORMS = [
    "linux",
    "darwin",
]

# Private to this file: leading underscore. Cannot be loaded from elsewhere.
_INTERNAL_VERSION = "1.0"

def version_string():
    return _INTERNAL_VERSION
