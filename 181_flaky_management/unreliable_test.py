"""Deliberately flaky: fails roughly one run in three."""

import os
import unittest


class UnreliableTest(unittest.TestCase):
    def test_sometimes_fails(self):
        # Uses the PID so the result varies between runs rather than within one.
        self.assertNotEqual(os.getpid() % 3, 0, "unlucky pid - simulated flake")


if __name__ == "__main__":
    unittest.main()
