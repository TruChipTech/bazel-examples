import sys

from polite import polite_greeting


def main():
    print(polite_greeting(sys.argv[1] if len(sys.argv) > 1 else "stranger"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
