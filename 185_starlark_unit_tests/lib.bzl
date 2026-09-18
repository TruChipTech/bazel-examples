"""Pure Starlark helpers - the kind of code that needs unit tests."""

# Starlark has NO `while` loop and NO recursion, so "repeat until stable" has
# to become a bounded `for` loop. This is a common shape in Starlark code.
_MAX_COLLAPSE_PASSES = 10

def normalize_target_name(raw):
    """Converts an arbitrary string into a valid, conventional target name."""
    if not raw:
        fail("normalize_target_name: name must not be empty")

    out = ""
    for ch in raw.lower().elems():
        if ch.isalnum():
            out += ch
        elif ch in " -_./":
            out += "_"

    # Collapse runs of underscores. Bounded, because Starlark has no `while`.
    for _ in range(_MAX_COLLAPSE_PASSES):
        if "__" not in out:
            break
        out = out.replace("__", "_")

    return out.strip("_")

def split_flags(flags):
    """Partitions a flag list into (defines, others)."""
    defines = []
    others = []
    for flag in flags:
        if flag.startswith("-D"):
            defines.append(flag[2:])
        else:
            others.append(flag)
    return struct(defines = defines, others = others)

def merge_settings(base, override):
    """Returns a new dict; later keys win. Never mutates the inputs."""
    result = dict(base)
    result.update(override)
    return result
