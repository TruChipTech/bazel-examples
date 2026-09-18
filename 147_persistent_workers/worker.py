"""A persistent worker speaking Bazel's JSON worker protocol.

Protocol (one JSON object per line):
  Bazel  -> worker : {"arguments": [...], "inputs": [...], "requestId": 0}
  worker -> Bazel  : {"exitCode": 0, "output": "...", "requestId": 0}

The process STAYS ALIVE between requests, so expensive startup (loading a
compiler, warming a JIT, parsing a schema) happens once instead of per action.
"""

import json
import os
import sys
import time

# Simulated expensive startup - paid once per worker process, not per action.
STARTED_AT = time.time()
REQUESTS_HANDLED = 0


def handle(arguments):
    """Does the actual work for one request."""
    global REQUESTS_HANDLED
    REQUESTS_HANDLED += 1

    output_path = None
    words = []
    for arg in arguments:
        if arg.startswith("--output="):
            output_path = arg[len("--output="):]
        elif arg.startswith("--word="):
            words.append(arg[len("--word="):])

    if output_path is None:
        return 1, "no --output given"

    with open(output_path, "w") as handle_out:
        handle_out.write("worker pid      : %d\n" % os.getpid())
        handle_out.write("requests so far : %d\n" % REQUESTS_HANDLED)
        handle_out.write("words           : %s\n" % ", ".join(words))

    return 0, "handled request %d in pid %d" % (REQUESTS_HANDLED, os.getpid())


def run_persistent():
    """The worker loop: read requests until stdin closes."""
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        request = json.loads(line)
        exit_code, message = handle(request.get("arguments", []))
        response = {
            "exitCode": exit_code,
            "output": message,
            "requestId": request.get("requestId", 0),
        }
        sys.stdout.write(json.dumps(response) + "\n")
        sys.stdout.flush()


def run_once(argv):
    """Standalone mode: Bazel falls back to this when workers are disabled."""
    args = argv
    if args and args[0].startswith("@"):
        with open(args[0][1:]) as handle_in:
            args = [l.rstrip("\n") for l in handle_in if l.strip()]
    exit_code, message = handle(args)
    sys.stderr.write(message + "\n")
    return exit_code


if __name__ == "__main__":
    # Bazel passes --persistent_worker when it wants worker mode.
    if "--persistent_worker" in sys.argv[1:]:
        run_persistent()
        sys.exit(0)
    sys.exit(run_once(sys.argv[1:]))

# cache-buster comment
