import unittest

from core import run


class CoreTest(unittest.TestCase):
    def test_run(self):
        self.assertEqual(run(), "core")


if __name__ == "__main__":
    unittest.main()
