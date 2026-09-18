import time
import unittest


class SlowTest(unittest.TestCase):
    def test_takes_a_moment(self):
        time.sleep(1.5)
        self.assertTrue(True)


if __name__ == "__main__":
    unittest.main()
