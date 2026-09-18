"""Symbolic macro finalizers: macros that run AFTER the rest of the package."""

load("@rules_python//python:defs.bzl", "py_test")

def _coverage_guard_impl(name, visibility, size, **kwargs):
    """Declares a test asserting every py_library in this package has a test.

    A FINALIZER runs after every other macro and target in the package has been
    declared, which is what lets it call native.existing_rules() and see the
    complete picture. An ordinary macro would only see what came before it.
    """
    rules = native.existing_rules()

    libraries = []
    tested = {}
    for rule_name, attrs in rules.items():
        kind = attrs.get("kind", "")
        if kind == "py_library":
            libraries.append(rule_name)
        elif kind == "py_test":
            # Convention: foo_test covers foo.
            if rule_name.endswith("_test"):
                tested[rule_name[:-len("_test")]] = True

    missing = sorted([lib for lib in libraries if lib not in tested])

    # Generate a test that fails if anything is untested.
    script_name = name + "_report.py"
    native.genrule(
        name = name + "_gen",
        outs = [script_name],
        cmd = """cat > $@ <<'PY'
import sys

MISSING = {missing}

if MISSING:
    print("libraries with no matching _test target:")
    for m in MISSING:
        print("  " + m)
    sys.exit(1)
print("every py_library in this package has a test")
PY
""".format(missing = repr(missing)),
    )

    py_test(
        name = name,
        size = size,
        srcs = [script_name],
        main = script_name,
        visibility = visibility,
        **kwargs
    )

coverage_guard = macro(
    implementation = _coverage_guard_impl,
    # Symbolic macros validate attributes strictly: passing `size` without
    # declaring it here fails with "no such attribute 'size'".
    attrs = {
        "size": attr.string(default = "small", configurable = False),
    },
    # finalizer = True is the whole point: this macro is expanded LAST.
    finalizer = True,
)
