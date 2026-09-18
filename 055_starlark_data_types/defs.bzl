"""Starlark data structures you will meet constantly."""

# --- dict -------------------------------------------------------------------
PLATFORM_FLAGS = {
    "linux": ["-DLINUX", "-pthread"],
    "darwin": ["-DDARWIN"],
    "windows": ["/DWINDOWS"],
}

# --- struct: an immutable record --------------------------------------------
# struct() is the workhorse for passing grouped data around in Starlark.
DEFAULT_SERVICE = struct(
    name = "unnamed",
    port = 8080,
    replicas = 1,
    tags = ["managed"],
)

def make_service(name, port = None, replicas = None):
    """Returns a new struct - structs are immutable, so we rebuild it."""
    return struct(
        name = name,
        port = port if port != None else DEFAULT_SERVICE.port,
        replicas = replicas if replicas != None else DEFAULT_SERVICE.replicas,
        tags = DEFAULT_SERVICE.tags,
    )

def describe(service):
    return "%s:%d x%d [%s]" % (
        service.name,
        service.port,
        service.replicas,
        ",".join(service.tags),
    )

def flags_for(os_name):
    # .get() with a default avoids a KeyError on an unknown key.
    return PLATFORM_FLAGS.get(os_name, [])
