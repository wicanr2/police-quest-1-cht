#!/usr/bin/env python3
"""Combine exact-key TSV skeletons while preserving first-seen order."""
from pathlib import Path
import argparse

ap = argparse.ArgumentParser()
ap.add_argument("output", type=Path)
ap.add_argument("inputs", nargs="+", type=Path)
a = ap.parse_args()
seen, rows = set(), []
for path in a.inputs:
    for line in path.read_text(encoding="utf-8").splitlines():
        if "\t" not in line:
            continue
        key, value = line.split("\t", 1)
        if key not in seen:
            seen.add(key)
            rows.append(f"{key}\t{value}")
a.output.parent.mkdir(parents=True, exist_ok=True)
a.output.write_text("\n".join(rows) + "\n", encoding="utf-8")
print(f"combined {len(rows)} unique keys -> {a.output}")
