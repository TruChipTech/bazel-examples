import unittest


class QuickTest(unittest.TestCase):
    def test_instant(self):
        self.assertEqual(1 + 1, 2)


if __name__ == "__main__":
    unittest.main()
