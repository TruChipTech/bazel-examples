"""Converts a CSV file to JSON. Used as a build tool, not shipped."""

import csv
import json
import sys


def main(argv):
    if len(argv) != 3:
        print("usage: csv_to_json INPUT OUTPUT", file=sys.stderr)
        return 2
    with open(argv[1], newline="") as handle:
        rows = list(csv.DictReader(handle))
    with open(argv[2], "w") as out:
        json.dump(rows, out, indent=2, sort_keys=True)
        out.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
