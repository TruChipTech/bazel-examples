import sys

with open(sys.argv[2], "w") as out:
    with open(sys.argv[1]) as handle:
        for line in handle:
            out.write("| " + line.rstrip() + "\n")
