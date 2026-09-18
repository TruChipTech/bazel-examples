"""Reads the batch the C++ collector produced and prints a report."""

import sys

from telemetry_pb2 import Batch, Level

LEVEL_NAMES = {
    Level.LEVEL_UNSPECIFIED: "UNSPEC",
    Level.LEVEL_INFO: "INFO",
    Level.LEVEL_WARN: "WARN",
    Level.LEVEL_ERROR: "ERROR",
}


def main(argv):
    if len(argv) != 2:
        print("usage: report INPUT", file=sys.stderr)
        return 2

    with open(argv[1], "rb") as handle:
        batch = Batch()
        batch.ParseFromString(handle.read())

    print(f"source: {batch.source}")
    print(f"samples: {len(batch.samples)}")
    for sample in batch.samples:
        print(f"  [{LEVEL_NAMES[sample.level]:>5}] {sample.metric} = {sample.value}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
