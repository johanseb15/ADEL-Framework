"""A small command-line application using only Python's standard library."""

import argparse


def main(argv=None):
    parser = argparse.ArgumentParser(description="Greet someone from the command line.")
    parser.add_argument("name", nargs="?", default="world", help="person to greet")
    args = parser.parse_args(argv)
    print("Hello, {}!".format(args.name))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
