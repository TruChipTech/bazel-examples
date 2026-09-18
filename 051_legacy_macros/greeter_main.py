import sys

from greeter import greet


def main():
    print(greet(sys.argv[1] if len(sys.argv) > 1 else "world"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
