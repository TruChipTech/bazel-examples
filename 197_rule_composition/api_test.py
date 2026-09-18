import unittest

from api import handle


class ApiTest(unittest.TestCase):
    def test_handle(self):
        self.assertEqual(handle(), "handled")


if __name__ == "__main__":
    unittest.main()
