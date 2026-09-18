import unittest

from python.runfiles import runfiles


class RunfilesTest(unittest.TestCase):
    def test_data_file_is_reachable(self):
        r = runfiles.Create()
        self.assertIsNotNone(r)
        path = r.Rlocation("_main/081_py_runfiles/assets/template.txt")
        self.assertIsNotNone(path, "Rlocation failed - wrong repo prefix?")
        with open(path) as handle:
            self.assertIn("{name}", handle.read())


if __name__ == "__main__":
    unittest.main()
