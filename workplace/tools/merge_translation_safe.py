#!/usr/bin/env python3
"""Merge batches while retaining skeleton rows whose source key contains an escaped tab."""
from pathlib import Path
import argparse

ap = argparse.ArgumentParser()
ap.add_argument("skeleton", type=Path)
ap.add_argument("batch_dir", type=Path)
ap.add_argument("output", type=Path)
a = ap.parse_args()

def read(path):
    rows = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if "\t" in line:
            key, value = line.split("\t", 1)
        else:
            key = value = line
        if key:
            rows[key] = value
    return rows

updates = {}
for path in sorted(a.batch_dir.glob("*.tsv")):
    updates.update(read(path))
rows = []
for key, old in read(a.skeleton).items():
    rows.append(f"{key}\t{updates.get(key, old)}")
a.output.write_text("\n".join(rows) + "\n", encoding="utf-8")
print(f"merged {len(updates)} batch keys into {len(rows)} skeleton rows")
