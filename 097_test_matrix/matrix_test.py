"""One test body, parameterized by command-line arguments."""

import sys
import unittest

BACKEND = "memory"
MODE = "sync"

for arg in sys.argv[1:]:
    if arg.startswith("--backend="):
        BACKEND = arg.split("=", 1)[1]
    elif arg.startswith("--mode="):
        MODE = arg.split("=", 1)[1]

# Bazel passes the args before unittest sees them; strip them out.
sys.argv = [sys.argv[0]]


class MatrixTest(unittest.TestCase):
    def test_configuration_is_valid(self):
        print(f"\nrunning with backend={BACKEND} mode={MODE}")
        self.assertIn(BACKEND, ("memory", "disk", "remote"))
        self.assertIn(MODE, ("sync", "async"))

    def test_combination_is_supported(self):
        # A real matrix test would exercise the backend here.
        unsupported = (BACKEND == "remote" and MODE == "sync")
        self.assertFalse(unsupported, "remote+sync is not a supported pairing")


if __name__ == "__main__":
    unittest.main()
