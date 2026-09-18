"""Deliberately includes a branch the test never exercises."""


def area(shape, *dims):
    if shape == "rect":
        return dims[0] * dims[1]
    if shape == "circle":
        return 3.14159 * dims[0] ** 2
    if shape == "triangle":
        # This branch is NOT covered by the test - watch it show up in the report.
        return 0.5 * dims[0] * dims[1]
    raise ValueError(f"unknown shape: {shape}")


def perimeter(shape, *dims):
    # An entirely uncovered function.
    if shape == "rect":
        return 2 * (dims[0] + dims[1])
    return 0
