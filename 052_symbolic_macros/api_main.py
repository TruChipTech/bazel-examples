import sys


def main():
    print("starting api with args:", sys.argv[1:])
    from api import handle
    print(handle("/health"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
