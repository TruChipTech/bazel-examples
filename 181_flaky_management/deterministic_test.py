import unittest


class DeterministicTest(unittest.TestCase):
    def test_stable(self):
        self.assertEqual(sorted([3, 1, 2]), [1, 2, 3])


if __name__ == "__main__":
    unittest.main()
