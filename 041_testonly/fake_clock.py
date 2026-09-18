"""A test double. Must never be linked into production code."""


class FakeClock:
    def __init__(self):
        self.now = 0

    def advance(self, seconds):
        self.now += seconds
