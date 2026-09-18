import unittest

from validators import clamp, is_email


class EmailTest(unittest.TestCase):
    def test_accepts_valid(self):
        self.assertTrue(is_email("dev@example.com"))

    def test_rejects_invalid(self):
        self.assertFalse(is_email("not-an-email"))
        self.assertFalse(is_email(""))
        self.assertFalse(is_email(None))


class ClampTest(unittest.TestCase):
    def test_within_range(self):
        self.assertEqual(clamp(5, 0, 10), 5)

    def test_clamps_both_ends(self):
        self.assertEqual(clamp(-3, 0, 10), 0)
        self.assertEqual(clamp(99, 0, 10), 10)

    def test_rejects_inverted_bounds(self):
        with self.assertRaises(ValueError):
            clamp(1, 10, 0)


if __name__ == "__main__":
    unittest.main()
