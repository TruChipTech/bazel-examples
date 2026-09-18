import sys

from store import TaskStore
from task_pb2 import Priority


def main(argv):
    store = TaskStore()
    store.add("t1", "write the build file", Priority.PRIORITY_HIGH)
    store.add("t2", "run the tests", Priority.PRIORITY_LOW)
    store.complete("t2")

    print(f"backend: {store.backend}")
    print(f"pending: {len(store.pending())}")
    for task in store.pending():
        print(f"  [{task.id}] {task.title}")

    # Prove the proto round-trips.
    restored = TaskStore.parse(store.serialize())
    print(f"round-trip pending: {len(restored.pending())}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
