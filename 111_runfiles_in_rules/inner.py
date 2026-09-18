import os
import sys

# This file is in the INNER binary's data. It is reachable only if the wrapper
# merged the inner binary's runfiles into its own.
DATA = os.path.join("111_runfiles_in_rules", "inner_data.txt")

if not os.path.exists(DATA):
    print("ERROR: inner binary cannot find its data - runfiles were not merged")
    sys.exit(1)

with open(DATA) as handle:
    print("inner ok:", handle.read().strip())
print("inner args:", sys.argv[1:])
