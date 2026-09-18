"""depset traversal orders and when they matter."""

OrderInfo = provider(fields = {"items": "depset of string"})

def _ordered_impl(ctx):
    transitive = [dep[OrderInfo].items for dep in ctx.attr.deps]

    items = depset(
        direct = [ctx.label.name],
        transitive = transitive,
        # The order determines how to_list() flattens the DAG:
        #
        #   "default"   unspecified; fastest. Use unless you need an order.
        #   "postorder" children BEFORE parents (dependencies first)
        #   "preorder"  parents BEFORE children (dependents first)
        #   "topological" parents before children, stable
        #
        # All depsets merged together must use a COMPATIBLE order, or Bazel
        # fails at analysis time.
        order = ctx.attr.order,
    )

    out = ctx.actions.declare_file(ctx.label.name + "_" + ctx.attr.order + ".txt")
    ctx.actions.write(
        output = out,
        content = "order=%s\n%s\n" % (ctx.attr.order, " -> ".join(items.to_list())),
    )

    return [
        DefaultInfo(files = depset([out])),
        OrderInfo(items = items),
    ]

ordered_node = rule(
    implementation = _ordered_impl,
    attrs = {
        "deps": attr.label_list(providers = [OrderInfo]),
        "order": attr.string(
            default = "postorder",
            values = [
                "default",
                "postorder",
                "preorder",
                "topological",
            ],
        ),
    },
)
