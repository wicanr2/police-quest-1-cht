#!/usr/bin/env python3
"""Copy only exact, already-translated keys from a reference UTF-8 TSV."""
from pathlib import Path
import argparse

ap = argparse.ArgumentParser()
ap.add_argument("skeleton", type=Path)
ap.add_argument("reference", type=Path)
ap.add_argument("output", type=Path)
a = ap.parse_args()

def read(path):
    out = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if "\t" in line:
            k, v = line.split("\t", 1)
            out[k] = v
    return out

ref = read(a.reference)
rows, matches = [], 0
for key, old in read(a.skeleton).items():
    value = ref.get(key, old)
    if value != old:
        matches += 1
    rows.append(f"{key}\t{value}")
a.output.write_text("\n".join(rows) + "\n", encoding="utf-8")
print(f"exact prefill {matches} rows -> {a.output}")
