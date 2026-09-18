"""Task storage, with a backend selected at BUILD time."""

from task_pb2 import Priority, Task, TaskList

# BACKEND is injected by the build via a generated module (see backend.bzl).
try:
    from backend_config import BACKEND
except ImportError:  # pragma: no cover
    BACKEND = "memory"


class TaskStore:
    def __init__(self):
        self._list = TaskList()

    @property
    def backend(self):
        return BACKEND

    def add(self, task_id, title, priority=Priority.PRIORITY_LOW):
        task = self._list.tasks.add()
        task.id = task_id
        task.title = title
        task.priority = priority
        return task

    def complete(self, task_id):
        for task in self._list.tasks:
            if task.id == task_id:
                task.done = True
                return True
        return False

    def pending(self):
        return [t for t in self._list.tasks if not t.done]

    def serialize(self):
        return self._list.SerializeToString()

    @staticmethod
    def parse(data):
        store = TaskStore()
        store._list.ParseFromString(data)
        return store
