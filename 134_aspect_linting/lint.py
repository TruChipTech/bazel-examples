"""A tiny linter used by the aspect."""

import re
import sys

RULES = [
    (re.compile(r"\bprint\("), "print() call - use logging"),
    (re.compile(r"\bTODO\b"), "TODO comment left in source"),
    (re.compile(r"^\s*except\s*:\s*$"), "bare except clause"),
]


def main(argv):
    src, report = argv[1], argv[2]
    findings = []
    with open(src) as handle:
        for lineno, line in enumerate(handle, 1):
            for pattern, message in RULES:
                if pattern.search(line):
                    findings.append(f"{src}:{lineno}: {message}")

    with open(report, "w") as out:
        if findings:
            out.write("\n".join(findings) + "\n")
        else:
            out.write(f"{src}: clean\n")

    # Exit 0 regardless: this aspect REPORTS rather than blocks. Change to
    # `return 1 if findings else 0` to make lint failures break the build.
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
