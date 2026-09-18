import platform
import unittest


class PlatformTest(unittest.TestCase):
    def test_runs_somewhere(self):
        print("\nrunning on:", platform.system())
        self.assertTrue(platform.system())


if __name__ == "__main__":
    unittest.main()
