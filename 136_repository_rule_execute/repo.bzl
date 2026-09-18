"""A repository rule that runs a program and generates a library."""

def _generated_lib_repo_impl(repository_ctx):
    count = repository_ctx.attr.module_count

    # repository_ctx.execute() runs a program on the host, right now.
    # Common uses: query a system tool's version, run a package manager,
    # invoke a generator.
    result = repository_ctx.execute(["python3", "-c", "import sys; print(sys.version_info[0], sys.version_info[1])"])
    if result.return_code != 0:
        fail("could not determine the python version: %s" % result.stderr)
    py_version = result.stdout.strip()

    srcs = []
    for i in range(count):
        name = "module_%d" % i
        repository_ctx.file(
            "%s.py" % name,
            content = 'NAME = "%s"\nPY_VERSION = "%s"\n\n\ndef describe():\n    return f"{NAME} generated for python {PY_VERSION}"\n' % (name, py_version),
        )
        srcs.append('"%s.py"' % name)

    repository_ctx.file(
        "BUILD.bazel",
        content = '''load("@rules_python//python:defs.bzl", "py_library")

py_library(
    name = "generated",
    srcs = [{srcs}],
    imports = ["."],
    visibility = ["//visibility:public"],
)
'''.format(srcs = ", ".join(srcs)),
    )

generated_lib_repo = repository_rule(
    implementation = _generated_lib_repo_impl,
    attrs = {
        "module_count": attr.int(default = 1),
    },
    doc = "Generates a Python library with N modules.",
)
