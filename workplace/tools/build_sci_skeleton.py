#!/usr/bin/env python3
"""合併 text/message 抽字 + script 內嵌字串 → translation/full_skeleton.tsv。

[HARD] script 內嵌字串常含硬換行 `\\n`(開場旁白、結局、死亡訊息這類 crawl)。
TSV 是逐行格式,含 `\\n` 的 key 會被拆成多個物理行 → merge_translations / build_cht
逐行讀時把無 TAB 的續行當 malformed 丟棄 → 整段從未進 translation.tsv、實機顯英文,
且覆蓋率統計看不出來(CLAUDE-PQ2 ④-S,SQ3 踩過)。

故此處在入 skeleton 前把所有空白正規化成單一空格 + trim,與引擎 `sciChtNormKey`
(sci.cpp)逐字一致 —— 引擎載入 tsv 的 key 與查表的遊戲字串兩邊都會正規化,
所以單行 key 對得上多行遊戲字串。原始多行原文另存供 crawl 對照/除錯。

用法:build_skeleton.py <text_skeleton.tsv> <script_strings.json> <out_full_skeleton.tsv>
"""
import json
import re
import sys
from pathlib import Path


def norm(s):
    """與引擎 sciChtNormKey 一致:所有空白(space/\\r/\\n/\\t)收斂成單一空格 + trim。"""
    return re.sub(r"[ \r\n\t]+", " ", s).strip()


def main():
    text_tsv, script_json, out_tsv = sys.argv[1], sys.argv[2], sys.argv[3]
    seen, rows = set(), []
    n_text = n_script = n_multiline = 0

    for line in Path(text_tsv).read_text(encoding="utf-8").splitlines():
        if "\t" not in line:
            continue
        key = norm(line.split("\t", 1)[0])
        if not key or key in seen:
            continue
        seen.add(key)
        rows.append(f"{key}\t{key}")
        n_text += 1

    multiline = []
    for s in json.loads(Path(script_json).read_text()):
        if "\n" in s or "\r" in s:
            n_multiline += 1
            multiline.append(s)
        key = norm(s)
        if not key or key in seen:
            continue
        seen.add(key)
        rows.append(f"{key}\t{key}")
        n_script += 1

    Path(out_tsv).write_text("\n".join(rows) + "\n", encoding="utf-8")
    if multiline:
        Path(out_tsv).with_name("script_multiline.json").write_text(
            json.dumps(multiline, ensure_ascii=False, indent=1), encoding="utf-8")
    print(f"full_skeleton: {len(rows)} 列(text {n_text} + script 新增 {n_script};"
          f"其中 script 多行原文 {n_multiline} 則已正規化成單行)→ {out_tsv}")


if __name__ == "__main__":
    main()
