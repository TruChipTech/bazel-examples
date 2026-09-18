"""The correct pattern, for comparison with slow.bzl."""

FastInfo = provider(fields = {"files": "DEPSET of File - the right way"})

def _fast_impl(ctx):
    # CORRECT: a depset node pointing at its children. O(1) to construct,
    # deduplicated, and never copied.
    all_files = depset(
        direct = ctx.files.srcs,
        transitive = [dep[FastInfo].files for dep in ctx.attr.deps],
    )

    out = ctx.actions.declare_file(ctx.label.name + ".fast")

    # to_list() happens ONCE, here, at the consumer.
    ctx.actions.write(output = out, content = "count: %d\n" % len(all_files.to_list()))

    return [
        DefaultInfo(files = depset([out])),
        FastInfo(files = all_files),
    ]

fast_node = rule(
    implementation = _fast_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(providers = [FastInfo]),
    },
)
