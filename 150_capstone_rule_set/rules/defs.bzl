"""The recipe rule set: library, binary, test, and a lint aspect."""

load(":providers.bzl", "RecipeInfo", "RecipeLintInfo")
load(":toolchain.bzl", "TOOLCHAIN_TYPE")

# --------------------------------------------------------------------------
# Shared transitive collection (sample 118)
# --------------------------------------------------------------------------

def _collect(ctx):
    return struct(
        sources = depset(
            direct = ctx.files.srcs,
            transitive = [d[RecipeInfo].transitive_sources for d in ctx.attr.deps],
        ),
        names = depset(
            direct = [ctx.label.name],
            transitive = [d[RecipeInfo].transitive_names for d in ctx.attr.deps],
        ),
    )

# --------------------------------------------------------------------------
# recipe_library
# --------------------------------------------------------------------------

def _recipe_library_impl(ctx):
    toolchain = ctx.toolchains[TOOLCHAIN_TYPE]
    collected = _collect(ctx)

    compiled = ctx.actions.declare_file(ctx.label.name + ".compiled")

    args = ctx.actions.args()
    args.add("--output", compiled)
    args.add("--name", ctx.label.name)
    args.add_all(ctx.files.srcs, before_each = "--src")
    args.use_param_file("@%s", use_always = False)
    args.set_param_file_format("multiline")

    ctx.actions.run(
        inputs = ctx.files.srcs,
        outputs = [compiled],
        executable = toolchain.compiler,
        arguments = [args],
        mnemonic = "RecipeCompile",
        progress_message = "Compiling recipe %s (%s)" % (ctx.label, toolchain.flavor),
    )

    # An optional extra output, built only on request (sample 119).
    manifest = ctx.actions.declare_file(ctx.label.name + ".manifest")
    ctx.actions.write(
        output = manifest,
        content = "closure: %s\n" % ", ".join(sorted(collected.names.to_list())),
    )

    return [
        DefaultInfo(files = depset([compiled])),
        RecipeInfo(
            transitive_sources = collected.sources,
            transitive_names = collected.names,
            compiled = compiled,
        ),
        OutputGroupInfo(manifest = depset([manifest])),
    ]

recipe_library = rule(
    implementation = _recipe_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = [".recipe"], mandatory = True),
        "deps": attr.label_list(providers = [RecipeInfo]),
    },
    toolchains = [TOOLCHAIN_TYPE],
    doc = "Compiles .recipe sources into a single compiled artifact.",
)

# --------------------------------------------------------------------------
# recipe_binary - an executable rule with runfiles (samples 111, 112)
# --------------------------------------------------------------------------

def _recipe_binary_impl(ctx):
    collected = _collect(ctx)
    launcher = ctx.actions.declare_file(ctx.label.name + ".sh")

    compiled_deps = [d[RecipeInfo].compiled for d in ctx.attr.deps]

    ctx.actions.write(
        output = launcher,
        is_executable = True,
        content = """#!/usr/bin/env bash
set -euo pipefail
echo "recipe program: {name}"
echo "closure: {closure}"
for f in {files}; do
  echo "--- $f"
  cat "$f"
done
""".format(
            name = ctx.label.name,
            closure = ", ".join(sorted(collected.names.to_list())),
            files = " ".join([f.short_path for f in compiled_deps]),
        ),
    )

    runfiles = ctx.runfiles(files = compiled_deps)
    for dep in ctx.attr.deps:
        runfiles = runfiles.merge(dep[DefaultInfo].default_runfiles)

    return [DefaultInfo(executable = launcher, runfiles = runfiles)]

recipe_binary = rule(
    implementation = _recipe_binary_impl,
    executable = True,
    attrs = {
        "srcs": attr.label_list(allow_files = [".recipe"]),
        "deps": attr.label_list(providers = [RecipeInfo], mandatory = True),
    },
    toolchains = [TOOLCHAIN_TYPE],
)

# --------------------------------------------------------------------------
# recipe_test - a custom test rule (sample 113)
# --------------------------------------------------------------------------

def _recipe_test_impl(ctx):
    script = ctx.actions.declare_file(ctx.label.name + "_test.sh")
    compiled = [d[RecipeInfo].compiled for d in ctx.attr.deps]

    checks = "\n".join([
        'check "%s" "%s"' % (f.short_path, ctx.attr.expect_contains)
        for f in compiled
    ])

    ctx.actions.write(
        output = script,
        is_executable = True,
        content = """#!/usr/bin/env bash
set -uo pipefail
failures=0
check() {{
  if [[ ! -f "$1" ]]; then
    echo "FAIL $1: missing"; failures=$((failures+1)); return
  fi
  if ! grep -q "$2" "$1"; then
    echo "FAIL $1: does not contain '$2'"; failures=$((failures+1)); return
  fi
  echo "ok   $1"
}}
{checks}
[[ $failures -eq 0 ]] || {{ echo "$failures failure(s)"; exit 1; }}
echo "all recipe assertions passed"
""".format(checks = checks),
    )

    return [DefaultInfo(
        executable = script,
        runfiles = ctx.runfiles(files = compiled),
    )]

recipe_test = rule(
    implementation = _recipe_test_impl,
    test = True,
    attrs = {
        "deps": attr.label_list(providers = [RecipeInfo], mandatory = True),
        "expect_contains": attr.string(mandatory = True),
    },
)

# --------------------------------------------------------------------------
# The lint aspect (samples 130-134)
# --------------------------------------------------------------------------

def _recipe_lint_aspect_impl(target, ctx):
    if ctx.rule.kind != "recipe_library":
        return [RecipeLintInfo(reports = depset())]

    toolchain = ctx.toolchains[TOOLCHAIN_TYPE]
    reports = []

    for f in ctx.rule.files.srcs:
        report = ctx.actions.declare_file("%s.%s.lint" % (target.label.name, f.basename))
        ctx.actions.run(
            inputs = [f],
            outputs = [report],
            executable = toolchain.linter,
            arguments = [f.path, report.path],
            mnemonic = "RecipeLint",
            progress_message = "Linting %s" % f.short_path,
        )
        reports.append(report)

    transitive = [
        d[RecipeLintInfo].reports
        for d in getattr(ctx.rule.attr, "deps", [])
        if RecipeLintInfo in d
    ]

    all_reports = depset(direct = reports, transitive = transitive)
    return [
        RecipeLintInfo(reports = all_reports),
        OutputGroupInfo(recipe_lint = all_reports),
    ]

recipe_lint_aspect = aspect(
    implementation = _recipe_lint_aspect_impl,
    attr_aspects = ["deps"],
    toolchains = [TOOLCHAIN_TYPE],
)

def _lint_report_impl(ctx):
    out = ctx.actions.declare_file(ctx.label.name + ".summary")
    reports = depset(transitive = [
        t[RecipeLintInfo].reports
        for t in ctx.attr.targets
    ]).to_list()

    ctx.actions.run_shell(
        inputs = reports,
        outputs = [out],
        arguments = [out.path] + [r.path for r in reports],
        command = 'out="$1"; shift; : > "$out"; for r in "$@"; do cat "$r" >> "$out"; done',
        mnemonic = "RecipeLintSummary",
    )
    return [DefaultInfo(files = depset([out]))]

recipe_lint_report = rule(
    implementation = _lint_report_impl,
    attrs = {
        "targets": attr.label_list(aspects = [recipe_lint_aspect], mandatory = True),
    },
)
