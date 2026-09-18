"""Locates a data file via the runfiles library rather than a relative path."""

import sys

from python.runfiles import runfiles


def main():
    r = runfiles.Create()
    if r is None:
        print("not running under Bazel runfiles")
        return 1

    # The key is "<repo>/<workspace-relative path>". "_main" is the main repo
    # under bzlmod.
    path = r.Rlocation("_main/081_py_runfiles/assets/template.txt")
    if path is None:
        print("Rlocation returned None - check the repository prefix")
        return 1

    with open(path) as handle:
        template = handle.read().strip()

    name = sys.argv[1] if len(sys.argv) > 1 else "developer"
    print("resolved:", path)
    print(template.format(name=name))
    return 0


if __name__ == "__main__":
    sys.exit(main())
