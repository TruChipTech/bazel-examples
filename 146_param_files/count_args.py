import sys

# A tool that supports param files must expand @file arguments itself.
def expand(argv):
    out = []
    for arg in argv:
        if arg.startswith("@"):
            with open(arg[1:]) as handle:
                out.extend(line.rstrip("\n") for line in handle if line.strip())
        else:
            out.append(arg)
    return out


args = expand(sys.argv[1:])
output = args[0]
rest = args[1:]

with open(output, "w") as handle:
    handle.write("expanded argument count: %d\n" % len(rest))
    handle.write("first: %s\n" % (rest[0] if rest else "<none>"))
    handle.write("last:  %s\n" % (rest[-1] if rest else "<none>"))
