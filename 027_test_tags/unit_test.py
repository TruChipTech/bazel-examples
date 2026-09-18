import unittest


class UnitTest(unittest.TestCase):
    def test_pure_logic(self):
        self.assertEqual(sorted([3, 1, 2]), [1, 2, 3])


if __name__ == "__main__":
    unittest.main()
