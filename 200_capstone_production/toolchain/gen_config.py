"""The config generator: turns key=value pairs into a C++ header."""
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
output = args[0]
pairs = [a.split("=", 1) for a in args[1:] if "=" in a]

with open(output, "w") as handle:
    handle.write("// GENERATED - do not edit\n")
    handle.write("#ifndef CAPSTONE_CONFIG_H_\n#define CAPSTONE_CONFIG_H_\n\n")
    for key, value in sorted(pairs):
        handle.write('#define CONFIG_%s "%s"\n' % (key.upper(), value))
    handle.write("\n#endif\n")
