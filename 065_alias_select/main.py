import sys

from crypto import backend


def main():
    print("crypto backend:", backend())
    return 0


if __name__ == "__main__":
    sys.exit(main())
