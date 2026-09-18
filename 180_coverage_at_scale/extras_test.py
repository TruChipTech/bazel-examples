import unittest

from extras import add_many


class ExtrasTest(unittest.TestCase):
    def test_add_many(self):
        self.assertEqual(add_many([1, 2, 3]), 6)


if __name__ == "__main__":
    unittest.main()
