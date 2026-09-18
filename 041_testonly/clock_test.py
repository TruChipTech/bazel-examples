import unittest

from fake_clock import FakeClock


class ClockTest(unittest.TestCase):
    def test_advances(self):
        c = FakeClock()
        c.advance(5)
        self.assertEqual(c.now, 5)


if __name__ == "__main__":
    unittest.main()
