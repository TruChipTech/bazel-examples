import unittest


class StableTest(unittest.TestCase):
    def test_deterministic(self):
        self.assertEqual(2 + 2, 4)


if __name__ == "__main__":
    unittest.main()
