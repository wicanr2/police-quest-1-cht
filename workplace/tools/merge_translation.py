#!/usr/bin/env python3
"""Merge exact-key translation batches into a skeleton TSV."""
from pathlib import Path
import argparse, csv

def read(path):
    out = {}
    with path.open(encoding="utf-8", newline="") as f:
        for row in csv.reader(f, delimiter="\t"):
            if len(row) >= 2:
                out[row[0]] = row[1]
    return out

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("skeleton", type=Path)
    ap.add_argument("batch_dir", type=Path)
    ap.add_argument("output", type=Path)
    args = ap.parse_args()
    updates = {}
    for p in sorted(args.batch_dir.glob("*.tsv")):
        updates.update(read(p))
    rows = []
    for key, old in read(args.skeleton).items():
        rows.append((key, updates.get(key, old)))
    with args.output.open("w", encoding="utf-8", newline="") as f:
        csv.writer(f, delimiter="\t", lineterminator="\n").writerows(rows)
    print(f"merged {len(updates)} batch keys into {len(rows)} skeleton rows")

if __name__ == "__main__":
    main()
