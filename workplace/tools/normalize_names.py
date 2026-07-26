#!/usr/bin/env python3
"""Converge drifted proper nouns and job titles in the Chinese column.

Independent translator batches drift even with a shared glossary: the same
character shows up transliterated in one batch and kept in English in another.
Rules are ordered, so longer context-bearing forms are rewritten before the
bare name they contain.
"""
from pathlib import Path
import argparse
import re

# Latin proper nouns kept in English need a space against an adjacent Han
# character, which is the convention in the existing translations. The class is
# deliberately Han-only: full-width punctuation already carries its own visual
# gap, and digits are excluded so placeholders such as %m46 stay glued to the
# text they introduce.
CJK = r"一-鿿"
NAMES = ["Lytton", "Sonny", "Bonds", "Dooley", "Morgan", "Laura", "Watts"]
SPACE_BEFORE = re.compile(f"(?<=[{CJK}])({'|'.join(NAMES)})")
SPACE_AFTER = re.compile(f"({'|'.join(NAMES)})(?=[{CJK}])")

# (from, to) applied in order to the Chinese value only.
RULES = [
    ("加州利頓", "加州 Lytton"),
    ("利頓警察局", "Lytton 警局"),
    ("利頓警局", "Lytton 警局"),
    ("立頓警局", "Lytton 警局"),
    ("利頓市", "Lytton 市"),
    ("立頓市", "Lytton 市"),
    ("利頓", "Lytton"),
    ("立頓", "Lytton"),
    ("杜利警佐", "Dooley 警佐"),
    ("杜利", "Dooley"),
    ("桑尼·邦茲", "Sonny Bonds"),
    ("桑尼", "Sonny"),
    ("邦茲", "Bonds"),
    ("摩根中尉", "Morgan 中尉"),
    ("摩根", "Morgan"),
    ("蘿拉·瓦茲", "Laura Watts"),
    ("蘿拉", "Laura"),
    ("偵探", "警探"),
    ("緝毒辦公室", "緝毒組辦公室"),
    # "保釋" reads as PRC/HK usage; Taiwanese legal Chinese says "交保".
    ("不得保釋令", "不得交保令"),
    ("不得保釋", "不得交保"),
    # Street names follow the same rule as every other place name: the proper
    # noun stays in English, only the generic suffix is translated.
    ("棕櫚街", "Palm 街"),
    ("公園大道", "Parkway 大道"),
    ("清水路", "Clearwater 路"),
    ("河路", "River 路"),
    # Taiwanese Chinese says 網路, not the PRC/academic 網絡.
    ("網絡", "網路"),
]


def convert(value):
    for src, dst in RULES:
        value = value.replace(src, dst)
    value = SPACE_BEFORE.sub(r" \1", value)
    value = SPACE_AFTER.sub(r"\1 ", value)
    return value


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("files", nargs="+", type=Path)
    ap.add_argument("--dry-run", action="store_true")
    args = ap.parse_args()

    changed_files = 0
    changed_lines = 0
    for path in args.files:
        out, touched = [], 0
        for line in path.read_text(encoding="utf-8").splitlines():
            if "\t" not in line:
                out.append(line)
                continue
            key, value = line.split("\t", 1)
            new = convert(value)
            if new != value:
                touched += 1
                if args.dry_run:
                    print(f"{path.name}: {value[:60]} -> {new[:60]}")
            out.append(f"{key}\t{new}")
        if touched:
            changed_files += 1
            changed_lines += touched
            if not args.dry_run:
                path.write_text("\n".join(out) + "\n", encoding="utf-8")
    print(f"{changed_lines} lines in {changed_files} files"
          f"{' (dry run)' if args.dry_run else ''}")


if __name__ == "__main__":
    main()
