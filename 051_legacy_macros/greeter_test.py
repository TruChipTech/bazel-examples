import unittest

from greeter import greet


class GreeterTest(unittest.TestCase):
    def test_greet(self):
        self.assertEqual(greet("bazel"), "hello, bazel")


if __name__ == "__main__":
    unittest.main()
