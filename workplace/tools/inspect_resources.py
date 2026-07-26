#!/usr/bin/env python3
"""Print reproducible, format-neutral M0 resource inventory."""
from pathlib import Path
import argparse


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("root", type=Path)
    args = ap.parse_args()
    for p in sorted(args.root.iterdir(), key=lambda x: x.name.lower()):
        if p.is_file():
            print(f"{p.name}\t{p.stat().st_size}")


if __name__ == "__main__":
    main()

