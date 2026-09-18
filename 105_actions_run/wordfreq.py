"""A build tool: counts word frequencies across input files."""

import collections
import sys


def main(argv):
    if len(argv) < 3:
        print("usage: wordfreq OUTPUT INPUT...", file=sys.stderr)
        return 2
    output, inputs = argv[1], argv[2:]
    counter = collections.Counter()
    for path in inputs:
        with open(path) as handle:
            counter.update(handle.read().lower().split())
    with open(output, "w") as out:
        for word, count in counter.most_common():
            out.write(f"{count:>4}  {word}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
