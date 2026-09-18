"""Extract the build-health metrics worth tracking from a BEP JSON file."""

import json
import sys


def main(argv):
    if len(argv) != 2:
        print("usage: bep_metrics BEP_JSON_FILE", file=sys.stderr)
        return 2

    metrics = {}
    test_results = []
    exit_code = None

    with open(argv[1]) as handle:
        for line in handle:
            line = line.strip()
            if not line:
                continue
            try:
                event = json.loads(line)
            except json.JSONDecodeError:
                continue

            if "buildMetrics" in event:
                metrics = event["buildMetrics"]
            if "testSummary" in event:
                test_results.append((
                    event.get("id", {}).get("testSummary", {}).get("label", "?"),
                    event["testSummary"].get("overallStatus", "?"),
                ))
            if "finished" in event:
                exit_code = event["finished"].get("exitCode", {}).get("name")

    action_summary = metrics.get("actionSummary", {})
    created = int(action_summary.get("actionsCreated", 0))
    executed = int(action_summary.get("actionsExecuted", 0))

    print("=== BUILD METRICS ===")
    print("actions created : %d" % created)
    print("actions executed: %d" % executed)
    if created:
        # The single most useful number to graph over time.
        print("cache hit rate  : %.1f%%" % (100.0 * (created - executed) / created))

    timing = metrics.get("timingMetrics", {})
    if timing:
        print("analysis phase  : %s ms" % timing.get("analysisPhaseTimeInMs", "?"))
        print("execution phase : %s ms" % timing.get("executionPhaseTimeInMs", "?"))
        print("wall time       : %s ms" % timing.get("wallTimeInMs", "?"))

    memory = metrics.get("memoryMetrics", {})
    if memory:
        print("peak heap (MB)  : %s" % memory.get("peakPostGcHeapSize", "?"))

    if test_results:
        print("\n=== TESTS ===")
        for label, status in sorted(test_results):
            print("  %-8s %s" % (status, label))

    print("\nexit status: %s" % exit_code)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
