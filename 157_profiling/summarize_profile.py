"""Summarize a Bazel --profile trace.

Bazel 9 removed `bazel analyze-profile`, so this reads the Chrome Trace Event
JSON that --profile produces and reports the same headline numbers: time per
phase and the slowest actions.
"""

import collections
import gzip
import json
import sys


def load(path):
    opener = gzip.open if path.endswith(".gz") else open
    with opener(path, "rt") as handle:
        return json.load(handle)


def main(argv):
    if len(argv) != 2:
        print("usage: summarize_profile PROFILE[.gz]", file=sys.stderr)
        return 2

    data = load(argv[1])
    events = data.get("traceEvents", [])

    # Phase markers are instant events on the "Critical Path"/phase lane.
    phases = [e for e in events if e.get("ph") == "i" and e.get("cat") == "build phase marker"]
    if phases:
        print("=== PHASES ===")
        phases.sort(key=lambda e: e.get("ts", 0))
        for current, following in zip(phases, phases[1:]):
            micros = following.get("ts", 0) - current.get("ts", 0)
            print(f"  {current.get('name', '?'):<34} {micros / 1e6:8.3f} s")

    # Complete events ('X') carry a duration.
    durations = collections.defaultdict(float)
    counts = collections.Counter()
    slowest = []
    for event in events:
        if event.get("ph") != "X":
            continue
        dur = event.get("dur", 0) / 1e6
        category = event.get("cat", "unknown")
        durations[category] += dur
        counts[category] += 1
        slowest.append((dur, event.get("name", "?"), category))

    print("\n=== TIME BY CATEGORY ===")
    for category, total in sorted(durations.items(), key=lambda kv: -kv[1])[:12]:
        print(f"  {category:<34} {total:8.3f} s  ({counts[category]} events)")

    print("\n=== SLOWEST INDIVIDUAL EVENTS ===")
    for dur, name, category in sorted(slowest, reverse=True)[:12]:
        print(f"  {dur:8.3f} s  [{category}] {name[:70]}")

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
