import time
import unittest


class CachedTest(unittest.TestCase):
    def test_prints_time(self):
        # The timestamp makes it obvious whether the test actually re-ran.
        print("\nran at:", time.time())
        self.assertTrue(True)


if __name__ == "__main__":
    unittest.main()
