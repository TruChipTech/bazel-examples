import os
import unittest


class IntegrationTest(unittest.TestCase):
    def test_environment(self):
        # A real integration test would reach a database or a service here.
        self.assertIn("TEST_TMPDIR", os.environ)


if __name__ == "__main__":
    unittest.main()
