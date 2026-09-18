"""The canonical transitive-collection pattern, as a miniature rule set."""

MiniLangInfo = provider(
    doc = "Compilation information for the mini language.",
    fields = {
        "transitive_sources": "depset of File - all sources, this target + deps",
        "transitive_includes": "depset of string - include directories",
        "direct_output": "File - this target's compiled artifact",
    },
)

def _collect(ctx):
    """Gather the transitive closure from deps. The reusable core."""
    return struct(
        sources = depset(
            direct = ctx.files.srcs,
            transitive = [
                dep[MiniLangInfo].transitive_sources
                for dep in ctx.attr.deps
            ],
        ),
        includes = depset(
            direct = [ctx.label.package],
            transitive = [
                dep[MiniLangInfo].transitive_includes
                for dep in ctx.attr.deps
            ],
        ),
    )

def _minilang_library_impl(ctx):
    collected = _collect(ctx)
    out = ctx.actions.declare_file(ctx.label.name + ".mo")

    args = ctx.actions.args()
    args.add("--output", out)
    # add_all consumes a depset DIRECTLY - no to_list(), no flattening in
    # Starlark, and the expansion is deferred until the action actually runs.
    args.add_all("--include", collected.includes, uniquify = True)
    args.add_all(ctx.files.srcs)

    ctx.actions.run_shell(
        # Passing a depset as inputs is also supported and preferred.
        inputs = collected.sources,
        outputs = [out],
        arguments = [args],
        command = 'shift 2; echo "compiled $# source(s)" > "$0"'.replace("$0", out.path),
        mnemonic = "MiniCompile",
        progress_message = "Compiling %s" % ctx.label,
    )

    return [
        DefaultInfo(files = depset([out])),
        MiniLangInfo(
            transitive_sources = collected.sources,
            transitive_includes = collected.includes,
            direct_output = out,
        ),
    ]

minilang_library = rule(
    implementation = _minilang_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".ml"]),
        "deps": attr.label_list(providers = [MiniLangInfo]),
    },
)

def _minilang_binary_impl(ctx):
    collected = _collect(ctx)
    out = ctx.actions.declare_file(ctx.label.name + ".summary")

    # The binary is the point where the whole closure is finally materialized.
    all_sources = collected.sources.to_list()

    ctx.actions.write(
        output = out,
        content = "binary %s\nsources in closure: %d\nincludes: %s\n" % (
            ctx.label.name,
            len(all_sources),
            ", ".join(sorted(collected.includes.to_list())),
        ),
    )
    return [DefaultInfo(files = depset([out]))]

minilang_binary = rule(
    implementation = _minilang_binary_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".ml"]),
        "deps": attr.label_list(providers = [MiniLangInfo]),
    },
)
