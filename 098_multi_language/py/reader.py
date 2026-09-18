"""The Python consumer: reads what the C++ producer wrote."""

import sys

from metric_pb2 import MetricSet


def main(argv):
    if len(argv) != 2:
        print("usage: reader INPUT", file=sys.stderr)
        return 2

    with open(argv[1], "rb") as handle:
        metric_set = MetricSet()
        metric_set.ParseFromString(handle.read())

    print(f"read {len(metric_set.metrics)} metrics")
    for metric in metric_set.metrics:
        labels = ",".join(f"{k}={v}" for k, v in sorted(metric.labels.items()))
        print(f"  {metric.name} = {metric.value} [{labels}]")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
