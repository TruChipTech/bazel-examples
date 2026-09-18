import unittest

from shapes import area


class ShapesTest(unittest.TestCase):
    def test_rect(self):
        self.assertEqual(area("rect", 3, 4), 12)

    def test_circle(self):
        self.assertAlmostEqual(area("circle", 1), 3.14159)

    def test_unknown(self):
        with self.assertRaises(ValueError):
            area("hexagon")


if __name__ == "__main__":
    unittest.main()
