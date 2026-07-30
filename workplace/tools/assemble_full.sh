#!/bin/sh
# 組裝「完整包」：patch-only 的全部內容 + 原始遊戲資源，解開就能玩。
#
#   assemble_full.sh <build_dir> <platform> [vga|ega]
#
# 第三個參數選版本，預設 vga：
#   vga  1992 VGA Remake（SCI）。資料是 RESOURCE.*，執行檔走 scummvm-pq1-sci，要 --language=tw。
#   ega  1987 原版（AGI）。資料是 VOL.*／LOGDIR 那組，執行檔走 scummvm-pq1-agi，
#        **不能**加 --language——AGI 在 ScummVM 走 fallback 偵測，語言設成非英文會無法啟動。
#
# ⚠ 完整包**只在本機組裝**，不進 Git、不上 GitHub Release。原始遊戲資源是 Sierra 的，
# 公開散布是另一回事。repo 裡留這支腳本與這份說明，是為了「rebuild 出得來、有紀錄可查」，
# 不是為了讓產物流出去。輸出固定落在 dist-all/（.gitignore 擋著）。
#
# patch-only 的 assemble_release.sh 有一段禁列掃描會擋下 RESOURCE.*／VOL.*；這支刻意
# 不掃，差別就在這裡，別把兩支搞混。
set -eu

build_dir=$1
platform=$2
edition=${3:-vga}

repo_root=${PQ1_REPO_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}
workplace=${PQ1_WORKPLACE:-$repo_root/workplace}
dist_dir=${PQ1_DIST_DIR:-$repo_root/dist-all}

case "$edition" in
vga)
	name="pq1-cht-vga-full-$platform"
	src=${PQ1_VGA_SOURCE:-$workplace/original/vga}
	marker=RESOURCE.MAP
	chtdir=$workplace/game/sci
	exe=scummvm-pq1-sci
	target=pq1sci
	langopt='--language=tw '
	label='VGA Remake（SCI，1992）'
	# ScummVM 只要資源檔與 message map；.DRV、INSTALL.EXE 那些 DOS 專用檔帶了也沒用。
	files='RESOURCE.MAP RESOURCE.MSG RESOURCE.CFG MESSAGE.MAP RESOURCE.000 RESOURCE.002 RESOURCE.003 RESOURCE.004 RESOURCE.005 RESOURCE.006'
	;;
ega)
	name="pq1-cht-ega-full-$platform"
	src=${PQ1_EGA_SOURCE:-$workplace/original/agi}
	marker=LOGDIR
	chtdir=$workplace/game/agi
	exe=scummvm-pq1-agi
	target=pq1
	langopt=''
	label='原版（AGI／EGA，1987）'
	files='LOGDIR PICDIR VIEWDIR SNDDIR OBJECT WORDS.TOK VOL.0 VOL.1 VOL.2'
	;;
*) echo "edition 只能是 vga 或 ega" >&2; exit 2 ;;
esac

out="$dist_dir/$name"
[ -f "$src/$marker" ] || { echo "找不到 $edition 原始資料：$src" >&2; exit 1; }

case "$out" in
*/dist-all/*) : ;;
*) echo "完整包只能輸出到 dist-all/（目前：$out）" >&2; exit 1 ;;
esac

rm -rf "$out"
mkdir -p "$out/game" "$out/cht" "$out/bin" "$out/docs"

for f in $files; do
	[ -f "$src/$f" ] && cp -a "$src/$f" "$out/game/"
done

cp -a "$chtdir"/*.fnt "$chtdir"/*.ovl "$chtdir/translation.tsv" "$out/cht/"
cp -a "$build_dir"/bin/. "$out/bin/"
cp -a "$repo_root/README.md" "$out/README.md"
cp -a "$repo_root/docs/中文條號速查.md" "$out/docs/"

# 只留這一版用得到的執行檔。另一版的 binary 在這裡沒有對應資料，帶了只會讓人誤會。
for f in "$out"/bin/scummvm-pq1-*; do
	case "$(basename "$f")" in
	"$exe"|"$exe".exe) : ;;
	scummvm-pq1-*) rm -f "$f" ;;
	esac
done

case "$platform" in
windows-*)
	cat > "$out/開始遊戲.bat" <<BAT
@echo off
cd /d "%~dp0"
bin\\$exe.exe --extrapath=cht $langopt--path=game $target
BAT
	;;
*)
	cat > "$out/開始遊戲.sh" <<SH
#!/bin/sh
cd "\$(dirname "\$0")"
exec bin/$exe --extrapath=cht $langopt--path=game $target
SH
	chmod +x "$out/開始遊戲.sh"
	;;
esac

if [ "$edition" = vga ]; then
	codes='拘留所登記窗口要輸入條號，對照表在 docs/中文條號速查.md。'
else
	codes='原版沒有查手冊型防拷，不需要條號表；docs/ 裡那份是 VGA 版用的。'
fi

cat > "$out/說明.txt" <<EOF
《警察故事 1：追捕死亡天使》$label 繁體中文完整包 —— $platform

這包含遊戲資料，解開就能玩，不必另外準備原版檔案。

玩法：
  Windows  雙擊 開始遊戲.bat
  其他     執行 ./開始遊戲.sh

手動啟動的話：
  bin/$exe --extrapath=cht $langopt--path=game $target

$codes

本包含原始遊戲資源，僅供自己保存與遊玩，請勿散布。
EOF

( cd "$out" && find . -type f ! -name SHA256SUMS -print | sort | xargs sha256sum > SHA256SUMS )

cd "$dist_dir"
rm -f "$name.zip" "$name.tar.gz"
case "$platform" in
windows-*) zip -qr "$name.zip" "$name"; echo "full package: $dist_dir/$name.zip" ;;
*)         tar -czf "$name.tar.gz" "$name"; echo "full package: $dist_dir/$name.tar.gz" ;;
esac
