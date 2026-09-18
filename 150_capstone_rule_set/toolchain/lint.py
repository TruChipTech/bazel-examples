"""The recipe linter."""
import sys

src, report = sys.argv[1], sys.argv[2]
findings = []
with open(src) as handle:
    for lineno, line in enumerate(handle, 1):
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if len(stripped) > 60:
            findings.append("%s:%d: step is too long (%d chars)" % (src, lineno, len(stripped)))
        if stripped != stripped.lower():
            findings.append("%s:%d: steps should be lowercase" % (src, lineno))

with open(report, "w") as handle:
    handle.write("\n".join(findings) + "\n" if findings else "%s: clean\n" % src)
