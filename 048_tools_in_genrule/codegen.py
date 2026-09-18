"""A tiny code generator: turns a list of names into a C header."""

import sys


def main(argv):
    if len(argv) != 3:
        print("usage: codegen INPUT OUTPUT", file=sys.stderr)
        return 2
    with open(argv[1]) as f:
        names = [line.strip() for line in f if line.strip()]
    with open(argv[2], "w") as out:
        out.write("// GENERATED FILE - do not edit\n")
        out.write("#ifndef GENERATED_CONSTANTS_H_\n")
        out.write("#define GENERATED_CONSTANTS_H_\n\n")
        for i, name in enumerate(names):
            out.write(f"constexpr int k{name.capitalize()} = {i};\n")
        out.write("\n#endif\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
