"""The O(n^2) anti-pattern, spelled out."""

SlowInfo = provider(fields = {"files": "LIST of File - the mistake"})

def _slow_impl(ctx):
    # ANTI-PATTERN: accumulating transitive data in a LIST.
    # Each level copies everything below it, so a chain of depth N copies the
    # deepest node's files N times - O(n^2) in both time and memory.
    all_files = list(ctx.files.srcs)
    for dep in ctx.attr.deps:
        all_files = all_files + dep[SlowInfo].files

    out = ctx.actions.declare_file(ctx.label.name + ".slow")
    ctx.actions.write(output = out, content = "count: %d\n" % len(all_files))

    return [
        DefaultInfo(files = depset([out])),
        SlowInfo(files = all_files),
    ]

slow_node = rule(
    implementation = _slow_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(providers = [SlowInfo]),
    },
)
