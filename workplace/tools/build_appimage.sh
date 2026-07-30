#!/bin/sh
# 把「完整包」打成單檔 AppImage：下載後 chmod +x 就能雙擊玩，不必解壓、不必裝 SDL2。
#
#   build_appimage.sh <vga|ega>
#
# 為什麼只對完整包做：AppImage 的賣點是自帶一切、點了就跑。patch-only 沒有遊戲資料，
# 包成 AppImage 還是得叫使用者傳 --path，那不如直接給 tar.gz。
#
# ⚠ 同 assemble_full.sh：產物含原始遊戲資源，只留本機，不進 Git 也不上 Release。
#
# 相依函式庫的取捨：SDL2 那串會整包帶進去，但 glibc/libstdc++/libgcc 這類**故意不帶**。
# 帶了會跟宿主的 loader 打架（AppImage 社群的老問題：bundle 到 libc 就變成只能在
# 打包機上跑）。代價是太舊的發行版跑不動，換來的是絕大多數現役發行版都能跑。
set -eu

edition=${1:-vga}
repo_root=${PQ1_REPO_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}
workplace=${PQ1_WORKPLACE:-$repo_root/workplace}
dist_dir=${PQ1_DIST_DIR:-$repo_root/dist-all}

case "$edition" in
vga) exe=scummvm-pq1-sci; target=pq1sci; langopt='--language=tw'; label='VGA Remake' ;;
ega) exe=scummvm-pq1-agi; target=pq1;    langopt='';              label='原版 EGA' ;;
*) echo "edition 只能是 vga 或 ega" >&2; exit 2 ;;
esac

srcpkg="$dist_dir/pq1-cht-$edition-full-linux-x86_64"
[ -d "$srcpkg" ] || { echo "找不到完整包目錄：$srcpkg（先跑 assemble_full.sh）" >&2; exit 1; }

name="pq1-cht-$edition-x86_64"
appdir="$dist_dir/$name.AppDir"
rm -rf "$appdir"
mkdir -p "$appdir/usr/bin" "$appdir/usr/lib" "$appdir/usr/share/pq1"

cp -a "$srcpkg/bin/$exe" "$appdir/usr/bin/"
cp -a "$srcpkg/game" "$srcpkg/cht" "$srcpkg/docs" "$appdir/usr/share/pq1/"
cp -a "$srcpkg/README.md" "$srcpkg/說明.txt" "$appdir/usr/share/pq1/"

# 帶進去的相依：ldd 全抓，再扣掉 loader 與 glibc 一家。
ldd "$appdir/usr/bin/$exe" | awk '/=> \//{print $3}' | sort -u | while read -r lib; do
	case "$(basename "$lib")" in
	libc.so.*|libm.so.*|libdl.so.*|libpthread.so.*|librt.so.*|ld-linux*|\
	libstdc++.so.*|libgcc_s.so.*|libresolv.so.*) continue ;;
	esac
	cp -Ln "$lib" "$appdir/usr/lib/" 2>/dev/null || true
done

cat > "$appdir/AppRun" <<APPRUN
#!/bin/sh
HERE="\$(dirname "\$(readlink -f "\$0")")"
export LD_LIBRARY_PATH="\$HERE/usr/lib:\${LD_LIBRARY_PATH:-}"
# 存檔寫使用者家目錄，不寫進唯讀的 AppImage 掛載點
SAVE="\${XDG_DATA_HOME:-\$HOME/.local/share}/pq1-cht-$edition"
mkdir -p "\$SAVE"
exec "\$HERE/usr/bin/$exe" \\
	--extrapath="\$HERE/usr/share/pq1/cht" \\
	--path="\$HERE/usr/share/pq1/game" \\
	--savepath="\$SAVE" \\
	$langopt "\$@" $target
APPRUN
chmod +x "$appdir/AppRun"

cat > "$appdir/pq1-cht-$edition.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Police Quest 1 CHT ($label)
Comment=警察故事 1：追捕死亡天使 繁體中文化
Exec=AppRun
Icon=pq1-cht-$edition
Categories=Game;AdventureGame;
Terminal=false
DESKTOP

# 圖示：從遊戲畫面裁一塊當底，比純文字方塊像個遊戲
base=$workplace/captures/pq1-agi-cht-start.png
if [ -f "$base" ]; then
	convert "$base" -resize 256x256^ -gravity center -extent 256x256 \
		"$appdir/pq1-cht-$edition.png"
else
	convert -size 256x256 xc:'#101830' -fill '#E8C36A' -gravity center \
		-pointsize 40 -annotate 0 'PQ1' "$appdir/pq1-cht-$edition.png"
fi
cp "$appdir/pq1-cht-$edition.png" "$appdir/.DirIcon"

# appimagetool 抓一次放 out/（gitignore 擋著）。容器裡沒有 FUSE，一律 --appimage-extract-and-run。
tool=$workplace/out/appimagetool
if [ ! -x "$tool" ]; then
	mkdir -p "$workplace/out"
	url=https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage
	curl -fsSL -o "$tool" "$url"
	chmod +x "$tool"
fi

ARCH=x86_64 "$tool" --appimage-extract-and-run "$appdir" "$dist_dir/$name.AppImage" >/dev/null 2>&1
rm -rf "$appdir"
chmod +x "$dist_dir/$name.AppImage"
echo "AppImage: $dist_dir/$name.AppImage"
