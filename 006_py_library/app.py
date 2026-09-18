import sys

# The import path mirrors the package path from the workspace root.
from textlib import slugify, titlecase


def main(argv):
    phrase = " ".join(argv[1:]) or "hello from bazel"
    print("slug: ", slugify(phrase))
    print("title:", titlecase(phrase))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
