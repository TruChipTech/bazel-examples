"""Demonstrates debugging tools available during the loading phase."""

def describe_target(name, srcs):
    """Prints diagnostics while BUILD files are being loaded."""

    # print() emits a DEBUG message during LOADING, not during the build.
    # It is the Starlark equivalent of a printf debugger.
    print("describe_target: name=%s, %d srcs" % (name, len(srcs)))

    # fail() aborts loading immediately with a clear message. Use it to
    # validate macro arguments so callers get a good error instead of a
    # confusing failure three layers down.
    if not srcs:
        fail("describe_target(%s): srcs must not be empty" % name)

    return srcs
