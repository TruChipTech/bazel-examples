"""Generating a matrix of test targets from a macro."""

load("@rules_python//python:defs.bzl", "py_test")

def matrix_test(name, src, backends, modes, deps = None):
    """Declares one test per (backend, mode) combination.

    Writing 6 near-identical py_test targets by hand invites drift: someone
    adds a tag to five of them and forgets the sixth. A macro makes the matrix
    the source of truth.
    """
    deps = deps or []
    all_tests = []

    for backend in backends:
        for mode in modes:
            test_name = "%s_%s_%s" % (name, backend, mode)
            py_test(
                name = test_name,
                size = "small",
                srcs = [src],
                args = [
                    "--backend=" + backend,
                    "--mode=" + mode,
                ],
                main = src,
                tags = [
                    "backend_" + backend,
                    "mode_" + mode,
                ],
                deps = deps,
            )
            all_tests.append(":" + test_name)

    native.test_suite(
        name = name,
        tests = all_tests,
    )
