#!/usr/bin/env python3
"""Apply batch TSVs over a skeleton, optionally retaining a prefilled base TSV."""
from pathlib import Path
import argparse

ap = argparse.ArgumentParser()
ap.add_argument("skeleton", type=Path)
ap.add_argument("output", type=Path)
ap.add_argument("--base", type=Path)
ap.add_argument("--batches", type=Path)
a = ap.parse_args()

def read(path):
    out = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if "\t" in line:
            k, v = line.split("\t", 1)
        else:
            k = v = line
        if k:
            out[k] = v
    return out

source = read(a.skeleton)
if a.base and a.base.exists():
    source.update(read(a.base))
updates = {}
if a.batches:
    for p in sorted(a.batches.glob("*.tsv")):
        updates.update(read(p))
rows = [f"{k}\t{updates.get(k, v)}" for k, v in source.items()]
# Runtime-only hooks are not part of the extracted game text skeleton. Keep
# explicitly namespaced PQ1 additions (for example the F1 help panel) in the
# shipped table while retaining exact-key behavior for ordinary game text.
for k, v in updates.items():
    if k.startswith("PQ1_") and a.output.name.startswith("sci-") and k not in source:
        rows.append(f"{k}\t{v}")
a.output.write_text("\n".join(rows) + "\n", encoding="utf-8")
print(f"merged {len(updates)} batch keys into {len(rows)} rows")
