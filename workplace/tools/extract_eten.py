#!/usr/bin/env python3
"""從倚天中文系統 3.53 的光碟映像抽出點陣字型。

    extract_eten.py [--iso ~/cht/etan_font/ET353S.iso] [--out out/eten]

抽三個檔（`eten_font.py` 需要的全部）：

    STDFONT.15    392820 B = 13094 字 × 30    漢字
    SPCFONT.15     12240 B =   408 字 × 30    全形標點／符號
    SPCFSUPP.15    10950 B =   365 字 × 30    符號補充

光碟是使用者自有物，映像與抽出的字型都不進 Git（`out/` 被 gitignore 擋著）。
這支只做「從 ISO9660 目錄樹撈檔」，不解壓縮——STD.24* 那組 24 點字是 ETUNPACK
壓縮的，本專案沒用到（hi-res 走 16x15 放大）。
"""
import argparse
import os
import struct

SEC = 2048
WANT = {"STDFONT.15": 392820, "SPCFONT.15": 12240, "SPCFSUPP.15": 10950}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--iso", default=os.path.expanduser("~/cht/etan_font/ET353S.iso"))
    ap.add_argument("--out", default="out/eten")
    a = ap.parse_args()

    os.makedirs(a.out, exist_ok=True)
    iso = open(a.iso, "rb")

    def sector(n):
        iso.seek(n * SEC)
        return iso.read(SEC)

    pvd = sector(16)
    if pvd[1:6] != b"CD001":
        raise SystemExit(f"{a.iso} 不是 ISO9660（第 16 磁區沒有 CD001）")
    root = pvd[156:156 + 34]
    found = {}

    def walk(lba, length, depth=0):
        data = b"".join(sector(lba + i) for i in range((length + SEC - 1) // SEC))
        p = 0
        while p < len(data):
            ln = data[p]
            if ln == 0:                      # 磁區內的填補，跳到下一個磁區
                p = (p // SEC + 1) * SEC
                if p >= len(data):
                    break
                continue
            rec = data[p:p + ln]
            ext = struct.unpack("<I", rec[2:6])[0]
            size = struct.unpack("<I", rec[10:14])[0]
            is_dir = rec[25] & 2
            name = rec[33:33 + rec[32]].decode("latin-1").split(";")[0].upper()
            if is_dir:
                if name not in ("\x00", "\x01") and depth < 4:
                    walk(ext, size, depth + 1)
            elif name in WANT and name not in found:
                iso.seek(ext * SEC)
                open(os.path.join(a.out, name), "wb").write(iso.read(size))
                found[name] = size
            p += ln

    walk(struct.unpack("<I", root[2:6])[0], struct.unpack("<I", root[10:14])[0])

    bad = []
    for name, expect in WANT.items():
        got = found.get(name)
        if got is None:
            bad.append(f"{name} 沒找到")
        elif got != expect:
            bad.append(f"{name} 大小 {got} 與預期 {expect} 不符")
        else:
            print(f"  {name:14s} {got:9d} B  ({got // 30} 字 × 30)")
    if bad:
        raise SystemExit("倚天字型抽取失敗：" + "；".join(bad))
    print(f"倚天點陣字 → {a.out}")


if __name__ == "__main__":
    main()
