import sys

ROWS = [
    ("alice", "platform", 5),
    ("bob", "product", 3),
    ("carol", "infra", 7),
]


def main(argv):
    with open(argv[1], "w") as out:
        out.write("name   team      years\n")
        out.write("-----  --------  -----\n")
        for name, team, years in ROWS:
            out.write(f"{name:<5}  {team:<8}  {years:>5}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
