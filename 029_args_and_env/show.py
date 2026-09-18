import os
import sys

print("argv[1:] =", sys.argv[1:])
print("GREETING =", os.environ.get("GREETING", "<unset>"))
print("MODE     =", os.environ.get("MODE", "<unset>"))
