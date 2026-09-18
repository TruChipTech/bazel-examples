"""Count words given on the command line."""

import sys
from collections import Counter


def main(argv):
    words = [w.lower() for w in argv[1:]]
    if not words:
        print("usage: wordcount WORD [WORD ...]")
        return 1
    for word, count in Counter(words).most_common():
        print(f"{count:>3}  {word}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
