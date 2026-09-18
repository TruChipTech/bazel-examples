"""A test suite large enough to benefit from sharding.

Bazel's sharding protocol has three parts, all implemented below:
  1. Read TEST_TOTAL_SHARDS and TEST_SHARD_INDEX from the environment.
  2. Touch the file named by TEST_SHARD_STATUS_FILE to advertise support.
     Bazel FAILS the test if you request sharding and never touch it.
  3. Run only the test cases belonging to this shard.

Most real runners (pytest with a plugin, JUnit, GoogleTest) do this for you.
It is spelled out here so the protocol is visible.
"""

import os
import sys
import unittest


def make_case(n):
    class Case(unittest.TestCase):
        def test_computation(self):
            self.assertEqual(sum(range(n)), n * (n - 1) // 2)

    Case.__name__ = "Case%d" % n
    return Case


# Generate 12 test classes so there is something to distribute.
for i in range(1, 13):
    globals()["Case%d" % i] = make_case(i * 100)


def shard_suite(suite, index, total):
    """Keep every `total`-th test, offset by `index`."""
    flat = list(unittest.TestSuite(suite))
    selected = unittest.TestSuite()
    for position, test in enumerate(_flatten(flat)):
        if position % total == index:
            selected.addTest(test)
    return selected


def _flatten(tests):
    for test in tests:
        if isinstance(test, unittest.TestSuite):
            for inner in _flatten(test):
                yield inner
        else:
            yield test


def main():
    total = int(os.environ.get("TEST_TOTAL_SHARDS", "1"))
    index = int(os.environ.get("TEST_SHARD_INDEX", "0"))

    # Step 2: advertise sharding support, or Bazel fails the test.
    status_file = os.environ.get("TEST_SHARD_STATUS_FILE")
    if status_file:
        with open(status_file, "w"):
            pass

    loader = unittest.TestLoader()
    suite = loader.loadTestsFromModule(sys.modules[__name__])
    if total > 1:
        suite = shard_suite(suite, index, total)

    print("[shard %d of %d] running %d cases" % (index, total, suite.countTestCases()))
    result = unittest.TextTestRunner(verbosity=1).run(suite)
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    sys.exit(main())
