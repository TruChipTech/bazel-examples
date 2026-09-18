import sys

src, out = sys.argv[1], sys.argv[2]
with open(src) as f:
    body = f.read()
with open(out, "w") as f:
    f.write("/* compiled by REFERENCE compiler (with checks) */\n")
    for i, line in enumerate(body.splitlines(), 1):
        f.write(f"{i:>3}: {line}\n")
