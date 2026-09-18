"""Reads a data file that was declared in the `data` attribute."""

import os
import sys

# A runfiles tree mirrors the workspace, so the path is the workspace-relative
# path of the file. Sample 081 shows the proper runfiles library instead.
DATA_PATH = os.path.join("012_data_and_runfiles", "greeting.txt")


def main():
    print("cwd:", os.getcwd())
    if not os.path.exists(DATA_PATH):
        print(f"ERROR: {DATA_PATH} is not in the runfiles tree")
        return 1
    with open(DATA_PATH) as handle:
        print("contents:", handle.read().strip())
    return 0


if __name__ == "__main__":
    sys.exit(main())
