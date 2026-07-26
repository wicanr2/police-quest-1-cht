#!/bin/sh
# 取得 patches/UPSTREAM_COMMIT.txt 指定的 pinned ScummVM 原始碼，放到 .upstream-src。
#
# 本機那兩個 /upstream-*-scummvm 掛載是編過的樹（含 .o/.a），直接複製來 configure 會
# 連到舊物件。這裡改成抓乾淨的 pinned commit，抓過就快取不重抓。
set -eu

dest=${1:-/workspace/.upstream-src}
commit=$(cat /workspace/patches/UPSTREAM_COMMIT.txt)

if [ -f "$dest/.pinned-$commit" ]; then
	echo "upstream 已是 pinned commit $commit（快取）"
	exit 0
fi

rm -rf "$dest"
mkdir -p "$dest"
cd "$dest"
git init -q
git remote add origin https://github.com/scummvm/scummvm.git
# 只抓這個 commit 的樹，不拉完整歷史。
git fetch -q --depth 1 origin "$commit"
git checkout -q FETCH_HEAD
touch ".pinned-$commit"
echo "upstream pinned commit $commit -> $dest"
