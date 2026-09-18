import unittest

from store import TaskStore
from task_pb2 import Priority


class StoreTest(unittest.TestCase):
    def test_add_and_pending(self):
        store = TaskStore()
        store.add("a", "first", Priority.PRIORITY_HIGH)
        store.add("b", "second")
        self.assertEqual(len(store.pending()), 2)

    def test_complete(self):
        store = TaskStore()
        store.add("a", "first")
        self.assertTrue(store.complete("a"))
        self.assertEqual(len(store.pending()), 0)

    def test_complete_unknown(self):
        self.assertFalse(TaskStore().complete("missing"))

    def test_roundtrip(self):
        store = TaskStore()
        store.add("a", "first", Priority.PRIORITY_HIGH)
        restored = TaskStore.parse(store.serialize())
        self.assertEqual(restored.pending()[0].title, "first")
        self.assertEqual(restored.pending()[0].priority, Priority.PRIORITY_HIGH)


if __name__ == "__main__":
    unittest.main()
