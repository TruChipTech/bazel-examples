"""Small reusable text helpers."""


def slugify(text):
    return "-".join(text.lower().split())


def titlecase(text):
    return " ".join(w.capitalize() for w in text.split())
