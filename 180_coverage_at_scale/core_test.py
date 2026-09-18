import unittest

from core import add, subtract


class CoreTest(unittest.TestCase):
    def test_add(self):
        self.assertEqual(add(2, 3), 5)

    def test_subtract(self):
        self.assertEqual(subtract(5, 2), 3)


if __name__ == "__main__":
    unittest.main()
