import unittest

from mathx import triple


class TripleTest(unittest.TestCase):
    def test_triple(self):
        self.assertEqual(triple(14), 42)


if __name__ == "__main__":
    unittest.main()
