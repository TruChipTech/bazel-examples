import sys

src, out = sys.argv[1], sys.argv[2]
with open(src) as f:
    body = f.read()
with open(out, "w") as f:
    f.write("/* compiled by FAST compiler */\n")
    f.write(body.upper())
