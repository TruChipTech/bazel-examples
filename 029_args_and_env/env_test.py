import os
import unittest


class EnvTest(unittest.TestCase):
    def test_env_is_passed(self):
        self.assertEqual(os.environ.get("EXPECTED"), "from-build-file")


if __name__ == "__main__":
    unittest.main()
