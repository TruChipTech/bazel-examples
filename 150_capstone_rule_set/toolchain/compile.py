"""The recipe compiler."""
import sys


def expand(argv):
    out = []
    for arg in argv:
        if arg.startswith("@"):
            with open(arg[1:]) as handle:
                out.extend(l.rstrip("\n") for l in handle if l.strip())
        else:
            out.append(arg)
    return out


args = expand(sys.argv[1:])
output = name = None
srcs = []
i = 0
while i < len(args):
    if args[i] == "--output":
        output = args[i + 1]; i += 2
    elif args[i] == "--name":
        name = args[i + 1]; i += 2
    elif args[i] == "--src":
        srcs.append(args[i + 1]); i += 2
    else:
        i += 1

steps = []
for path in srcs:
    with open(path) as handle:
        steps.extend(l.strip() for l in handle if l.strip() and not l.startswith("#"))

with open(output, "w") as handle:
    handle.write("RECIPE %s\n" % name)
    handle.write("steps: %d\n" % len(steps))
    for n, step in enumerate(steps, 1):
        handle.write("  %d. %s\n" % (n, step))
