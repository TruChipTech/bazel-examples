"""A custom TEST rule: validates files against simple rules."""

def _schema_test_impl(ctx):
    script = ctx.actions.declare_file(ctx.label.name + "_test.sh")

    checks = []
    for f in ctx.files.srcs:
        checks.append('check_file "%s"' % f.short_path)

    ctx.actions.write(
        output = script,
        is_executable = True,
        content = """#!/usr/bin/env bash
set -uo pipefail

failures=0
required_key="{required_key}"

check_file() {{
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "FAIL $path: not found in runfiles"
    failures=$((failures + 1))
    return
  fi
  if ! grep -q "^${{required_key}}:" "$path"; then
    echo "FAIL $path: missing required key '${{required_key}}'"
    failures=$((failures + 1))
    return
  fi
  echo "ok   $path"
}}

{checks}

if [[ $failures -gt 0 ]]; then
  echo "$failures file(s) failed validation"
  exit 1
fi
echo "all files valid"
exit 0
""".format(
            required_key = ctx.attr.required_key,
            checks = "\n".join(checks),
        ),
    )

    return [
        DefaultInfo(
            executable = script,
            # A test's inputs must be in RUNFILES - the test runs from the
            # runfiles tree, not the execroot.
            runfiles = ctx.runfiles(files = ctx.files.srcs),
        ),
    ]

schema_test = rule(
    implementation = _schema_test_impl,
    # test = True instead of executable = True. This makes it a *_test rule:
    # `bazel test` runs it, the result is cached, and it gets the test
    # environment (TEST_TMPDIR, TEST_SHARD_INDEX, ...).
    test = True,
    attrs = {
        "srcs": attr.label_list(allow_files = True, mandatory = True),
        "required_key": attr.string(default = "name"),
    },
)
