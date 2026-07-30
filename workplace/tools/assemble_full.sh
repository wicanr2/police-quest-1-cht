#!/bin/sh
# 組裝 VGA Remake 的「完整包」：patch-only 的全部內容 + 原始遊戲資源，解開就能玩。
#
#   assemble_full.sh <build_dir> <platform>
#
# ⚠ 完整包**只在本機組裝**，不進 Git、不上 GitHub Release。原始 RESOURCE.* 是 Sierra
# 的遊戲資源，公開散布是另一回事。repo 裡留這支腳本與這份說明，是為了「rebuild 出得來、
# 有紀錄可查」，不是為了讓產物流出去。輸出固定落在 dist-all/（.gitignore 第 8 行擋著）。
#
# patch-only 的 assemble_release.sh 有一段禁列掃描會擋下 RESOURCE.*；這支刻意不掃，
# 差別就在這裡，別把兩支搞混。
set -eu

build_dir=$1
platform=$2

repo_root=${PQ1_REPO_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}
workplace=${PQ1_WORKPLACE:-$repo_root/workplace}
dist_dir=${PQ1_DIST_DIR:-$repo_root/dist-all}
name="pq1-cht-vga-full-$platform"
out="$dist_dir/$name"

src=${PQ1_VGA_SOURCE:-$workplace/original/vga}
[ -f "$src/RESOURCE.MAP" ] || { echo "找不到 VGA 原始資料：$src" >&2; exit 1; }

case "$out" in
*/dist-all/*) : ;;
*) echo "完整包只能輸出到 dist-all/（目前：$out）" >&2; exit 1 ;;
esac

rm -rf "$out"
mkdir -p "$out/game" "$out/cht" "$out/bin" "$out/docs"

# ScummVM 只需要資源檔與 message map；.DRV、INSTALL.EXE、SCIDHUV.EXE 那些 DOS 專用檔
# 帶了也沒用，順手不收。原 repack 附的攻略／防拷答案／Patch 目錄同樣不收。
for f in RESOURCE.MAP RESOURCE.MSG RESOURCE.CFG MESSAGE.MAP RESOURCE.000 RESOURCE.002 \
         RESOURCE.003 RESOURCE.004 RESOURCE.005 RESOURCE.006; do
	[ -f "$src/$f" ] && cp -a "$src/$f" "$out/game/"
done

cp -a "$workplace"/game/sci/*.fnt "$workplace"/game/sci/*.ovl \
      "$workplace/game/sci/translation.tsv" "$out/cht/"
cp -a "$build_dir"/bin/. "$out/bin/"
cp -a "$repo_root/README.md" "$out/README.md"
cp -a "$repo_root/docs/中文條號速查.md" "$out/docs/"

# AGI 版的執行檔在完整包裡沒有對應資料，帶了只會讓人誤會。
rm -f "$out"/bin/scummvm-pq1-agi "$out"/bin/scummvm-pq1-agi.exe

case "$platform" in
windows-*)
	cat > "$out/開始遊戲.bat" <<'BAT'
@echo off
cd /d "%~dp0"
bin\scummvm-pq1-sci.exe --extrapath=cht --language=tw --path=game pq1sci
BAT
	;;
*)
	cat > "$out/開始遊戲.sh" <<'SH'
#!/bin/sh
cd "$(dirname "$0")"
exec bin/scummvm-pq1-sci --extrapath=cht --language=tw --path=game pq1sci
SH
	chmod +x "$out/開始遊戲.sh"
	;;
esac

cat > "$out/說明.txt" <<EOF
《警察故事 1：追捕死亡天使》VGA Remake 繁體中文完整包 —— $platform

這包含遊戲資料，解開就能玩，不必另外準備原版檔案。

玩法：
  Windows  雙擊 開始遊戲.bat
  其他     執行 ./開始遊戲.sh

手動啟動的話：
  bin/scummvm-pq1-sci --extrapath=cht --language=tw --path=game pq1sci

拘留所登記窗口要輸入條號，對照表在 docs/中文條號速查.md。

本包含原始遊戲資源，僅供自己保存與遊玩，請勿散布。
EOF

( cd "$out" && find . -type f ! -name SHA256SUMS -print | sort | xargs sha256sum > SHA256SUMS )

cd "$dist_dir"
rm -f "$name.zip" "$name.tar.gz"
case "$platform" in
windows-*) zip -qr "$name.zip" "$name"; echo "full package: $dist_dir/$name.zip" ;;
*)         tar -czf "$name.tar.gz" "$name"; echo "full package: $dist_dir/$name.tar.gz" ;;
esac
