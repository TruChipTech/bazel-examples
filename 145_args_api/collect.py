import sys

out = sys.argv[1]
with open(out, "w") as handle:
    handle.write("received %d arguments\n" % (len(sys.argv) - 2))
    for arg in sys.argv[2:]:
        handle.write("  " + arg + "\n")
