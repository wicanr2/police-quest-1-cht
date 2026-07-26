#!/usr/bin/env python3
"""Validate exact-key TSVs for duplicates, placeholders and Big5 encodability."""
from pathlib import Path
from collections import Counter
import argparse, re

TOKEN = re.compile(r"%(?:[sddux]|m\d+|v\d+|w\d+|g\d+|[0-9]+)")
ap = argparse.ArgumentParser()
ap.add_argument("tsv", type=Path)
a = ap.parse_args()
seen, errors, translated = set(), [], 0
for no, line in enumerate(a.tsv.read_text(encoding="utf-8").splitlines(), 1):
    if "\t" not in line:
        errors.append(f"line {no}: missing tab")
        continue
    key, value = line.split("\t", 1)
    if key in seen:
        errors.append(f"line {no}: duplicate key")
    seen.add(key)
    if value != key:
        translated += 1
    if Counter(TOKEN.findall(key)) != Counter(TOKEN.findall(value)):
        errors.append(f"line {no}: placeholder mismatch: {key!r}")
    try:
        value.encode("big5")
    except UnicodeEncodeError as exc:
        errors.append(f"line {no}: non-Big5 value: {exc}")
print(f"{a.tsv}: {translated}/{len(seen)} translated, {len(errors)} errors")
if errors:
    print("\n".join(errors[:40]))
    raise SystemExit(1)
