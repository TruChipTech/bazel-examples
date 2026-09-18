import sys

import module_0
import module_1
import module_2


def main():
    for module in (module_0, module_1, module_2):
        print(module.describe())
    return 0


if __name__ == "__main__":
    sys.exit(main())
