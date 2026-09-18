import unittest

from alpha import alpha


class AlphaTest(unittest.TestCase):
    def test_alpha(self):
        self.assertEqual(alpha(), "alpha")


if __name__ == "__main__":
    unittest.main()
