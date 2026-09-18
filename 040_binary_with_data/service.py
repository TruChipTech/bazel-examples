"""A small program that reads several runtime data files."""

import json
import os
import sys

BASE = os.path.join("040_binary_with_data", "config")


def main():
    with open(os.path.join(BASE, "banner.txt")) as f:
        print(f.read())
    with open(os.path.join(BASE, "settings.json")) as f:
        settings = json.load(f)
    print(f"starting {settings['name']} on port {settings['port']}")
    print(f"debug mode: {settings['debug']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
