"""Generates an unpredictable number of files into a directory."""

import os
import sys


def main(argv):
    outdir = argv[1]
    pages = argv[2:]
    os.makedirs(outdir, exist_ok=True)
    for page in pages:
        with open(os.path.join(outdir, f"{page}.html"), "w") as handle:
            handle.write(f"<!doctype html>\n<title>{page}</title>\n<h1>{page}</h1>\n")
    with open(os.path.join(outdir, "index.html"), "w") as handle:
        handle.write("<!doctype html>\n<title>index</title>\n<ul>\n")
        for page in pages:
            handle.write(f'<li><a href="{page}.html">{page}</a></li>\n')
        handle.write("</ul>\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
