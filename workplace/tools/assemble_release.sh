#!/bin/sh
# 組裝單一平台的 patch-only 交付包。
#
# 用法：assemble_release.sh <build_dir> <platform>
#   build_dir  含 bin/ 的目錄（各平台的 CI job 先把 binary 放進 <build_dir>/bin/）
#   platform   例如 linux-x86_64、windows-x86_64、macos-universal
#
# 刻意只收專案自有的 patch、工具、翻譯、字型與 binary。原始 RESOURCE/VOL/DOS 檔
# 一律不走訪，最後還會再掃一次確認沒有混進去。
set -eu

build_dir=$1
platform=$2

# 預設從腳本位置推導 <repo>/workplace/tools/。容器內 workplace 直接掛成 /workspace、
# repo 根另外掛成唯讀的 /source，這時用這兩個環境變數指路。
repo_root=${PQ1_REPO_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}
workplace=${PQ1_WORKPLACE:-$repo_root/workplace}
name="pq1-cht-$platform"
# 容器內 repo 根是唯讀掛載，本機建置時用 PQ1_DIST_DIR 指到可寫的位置。
dist_dir=${PQ1_DIST_DIR:-$repo_root/dist-all}
out="$dist_dir/$name"

rm -rf "$out"
mkdir -p "$dist_dir"
mkdir -p "$out/patches" "$out/tools" "$out/translation" "$out/game/agi" "$out/game/sci" "$out/bin"

cp -a "$workplace/patches/." "$out/patches/"
cp -a "$workplace/tools/." "$out/tools/"
cp -a "$workplace"/translation/*.tsv "$out/translation/"
cp -a "$workplace"/translation/LOCALIZE_INSTRUCTIONS.md "$out/translation/"
cp -a "$workplace"/game/agi/*.fnt "$workplace"/game/agi/*.ovl \
      "$workplace/game/agi/translation.tsv" "$out/game/agi/"
cp -a "$workplace"/game/sci/*.fnt "$workplace"/game/sci/*.ovl \
      "$workplace/game/sci/translation.tsv" "$out/game/sci/"
cp -a "$build_dir"/bin/. "$out/bin/"
cp -a "$repo_root/README.md" "$out/README.md"
cp -a "$workplace/CONTEXT.md" "$workplace/WORKLIST.md" "$out/"

# README 內嵌的畫面也一起帶，否則包內的 README 全是破圖。只收它實際引用的那幾張。
mkdir -p "$out/workplace/captures"
grep -o 'workplace/captures/[^)]*\.png' "$out/README.md" | sort -u | while read -r shot; do
	[ -f "$repo_root/$shot" ] && cp -a "$repo_root/$shot" "$out/workplace/captures/"
done

cat > "$out/安裝說明.txt" <<EOF
《警察故事 1：追捕死亡天使》繁體中文化 —— $platform

本包只含中文化資料與打了中文 patch 的 ScummVM 執行檔，
不含遊戲本身。請自行準備合法取得的原始遊戲資料。

安裝：
1. 把原版 Floppy DOS（AGI）的遊戲檔放在自己的資料夾，
   VGA Remake（SCI）的檔案放另一個資料夾，兩者不要混。
2. 原版走 bin/ 裡的 scummvm-pq1-agi，VGA Remake 走 scummvm-pq1-sci。
3. 啟動時把中文資料掛進去：
     AGI：scummvm-pq1-agi --extrapath=<本包>/game/agi --path=<你的遊戲資料夾>
     SCI：scummvm-pq1-sci --extrapath=<本包>/game/sci --language=tw --path=<你的遊戲資料夾>

注意：
- AGI 版靠「game/agi 裡有沒有 pq1_big5.fnt」決定要不要開中文，不要加 --language。
  AGI 在 ScummVM 走 fallback 偵測，target 語言設成非英文會無法啟動。
- SCI 版則相反，需要 --language=tw。
- 校驗檔案完整性：對照本包內的 SHA256SUMS。
EOF

# patch-only 邊界：原始遊戲資源絕對不能混進交付包。
find "$out" -type f | sort | while read -r f; do
	case "$f" in
	*/RESOURCE.*|*/VOL.*|*/LOGDIR|*/PICDIR|*/VIEWDIR|*/SNDDIR|*/OBJECT|*/WORDS.TOK|*/INTERP.*|*/MT32.DRV|*.ROM|*.zip)
		echo "forbidden file in patch package: $f" >&2
		exit 1
		;;
	esac
done

# macOS 沒有 GNU 的 sha256sum，只有 shasum。兩者的輸出格式與 -c 行為相容。
if command -v sha256sum >/dev/null 2>&1; then
	sha256() { xargs sha256sum; }
else
	sha256() { xargs shasum -a 256; }
fi

# 相對路徑：玩家解包後是在包目錄下跑 sha256sum -c，記成打包機的絕對路徑會全數 not found。
( cd "$out" && find . -type f ! -name SHA256SUMS -print | sort | sha256 > SHA256SUMS )

cd "$dist_dir"
# 先刪舊檔：zip 對既有壓縮檔是「更新」模式，上一版多打進去的東西不會被移除。
rm -f "$name.zip" "$name.tar.gz"
case "$platform" in
windows-*)
	zip -qr "$name.zip" "$name"
	echo "release package: $dist_dir/$name.zip"
	;;
*)
	tar -czf "$name.tar.gz" "$name"
	echo "release package: $dist_dir/$name.tar.gz"
	;;
esac
