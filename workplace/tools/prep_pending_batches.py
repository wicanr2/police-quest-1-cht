#!/usr/bin/env python3
"""Split untranslated keys into per-batch TSV worklists for translator subagents.

Keys that are AGI opcode names, parser vocabulary or other engine-internal
identifiers never reach displayText, so they are excluded instead of being
handed to a translator.
"""
from pathlib import Path
import argparse
import re

IDENTIFIER = re.compile(r"^[a-z][a-z0-9._%\-]*$")


def read_tsv(path):
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if "\t" in line:
            key, value = line.split("\t", 1)
        else:
            key = value = line
        if key:
            rows.append((key, value))
    return rows


def is_internal(key):
    """Engine-internal identifier: AGI opcodes, said-words, plate numbers."""
    return bool(IDENTIFIER.match(key))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("tsv", type=Path)
    ap.add_argument("outdir", type=Path)
    ap.add_argument("prefix")
    ap.add_argument("--size", type=int, default=128)
    args = ap.parse_args()

    pending, skipped = [], []
    for key, value in read_tsv(args.tsv):
        if value and value != key:
            continue
        (skipped if is_internal(key) else pending).append(key)

    args.outdir.mkdir(parents=True, exist_ok=True)
    batches = 0
    for index in range(0, len(pending), args.size):
        batches += 1
        chunk = pending[index:index + args.size]
        out = args.outdir / f"{args.prefix}-{batches:02d}.tsv"
        out.write_text("\n".join(chunk) + "\n", encoding="utf-8")

    (args.outdir / f"{args.prefix}-skipped.txt").write_text(
        "\n".join(skipped) + "\n", encoding="utf-8")
    print(f"{args.tsv.name}: pending={len(pending)} skipped={len(skipped)} "
          f"batches={batches}")


if __name__ == "__main__":
    main()
