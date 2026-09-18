from core import add


def add_many(values):
    total = 0
    for v in values:
        total = add(total, v)
    return total
