import os
import sys

print("files visible in runfiles:")
for root, _dirs, files in os.walk("."):
    for name in sorted(files):
        path = os.path.join(root, name)
        if "110_default_info" in path:
            print("  ", path)
sys.exit(0)
