#!/usr/bin/env python3
"""Verify a translated batch against its pending worklist.

The lookup key is the English source line, so a batch whose keys drifted from
the worklist would silently drop translations at merge time. This checks key
identity line by line, placeholder parity and Big5 encodability before the
batch is allowed into translation/batch/.
"""
from pathlib import Path
from collections import Counter
import argparse
import re
import sys

TOKEN = re.compile(r"%(?:[sdux]|m\d+|v\d+|w\d+|g\d+|[0-9]+)")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("pending", type=Path, help="worklist of English keys")
    ap.add_argument("batch", type=Path, help="translated TSV")
    args = ap.parse_args()

    want = args.pending.read_text(encoding="utf-8").splitlines()
    got = args.batch.read_text(encoding="utf-8").splitlines()
    errors = []

    if len(want) != len(got):
        errors.append(f"line count: worklist {len(want)} vs batch {len(got)}")

    translated = 0
    for no, (key, line) in enumerate(zip(want, got), 1):
        if "\t" not in line:
            errors.append(f"line {no}: missing tab")
            continue
        got_key, value = line.split("\t", 1)
        if got_key != key:
            errors.append(f"line {no}: key drift: {key!r} -> {got_key!r}")
            continue
        if not value:
            errors.append(f"line {no}: empty value")
            continue
        if value != key:
            translated += 1
        if Counter(TOKEN.findall(key)) != Counter(TOKEN.findall(value)):
            errors.append(f"line {no}: placeholder mismatch: {key!r}")
        if key.count("\\n") != value.count("\\n"):
            errors.append(f"line {no}: newline-code count changed: {key!r}")
        try:
            value.encode("big5")
        except UnicodeEncodeError as exc:
            bad = value[exc.start:exc.end]
            errors.append(f"line {no}: non-Big5 char {bad!r}")

    print(f"{args.batch.name}: {translated}/{len(want)} translated, "
          f"{len(errors)} errors")
    if errors:
        print("\n".join(errors[:40]))
        sys.exit(1)


if __name__ == "__main__":
    main()
