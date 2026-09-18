import unittest

from mathx import double


class DoubleTest(unittest.TestCase):
    def test_double(self):
        self.assertEqual(double(21), 42)


if __name__ == "__main__":
    unittest.main()
