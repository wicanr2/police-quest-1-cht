#!/bin/sh
# 在 pq1-mingw 容器內用 mingw-w64 交叉編譯 Windows 版，並組出交付包。
#
#   docker compose -f docker/compose.yml run --rm pq1-mingw sh tools/build_windows_release.sh
#
# 產物：workplace/dist-all/pq1-cht-windows-x86_64.zip
set -eu

sdl_prefix=${SDL_MINGW_PREFIX:-/opt/sdl2-mingw}
src=/workspace/.upstream-src
out=/workspace/.build-win

sh /workspace/tools/fetch_upstream.sh "$src"

rm -rf "$out"
mkdir -p "$out/bin"

for engine in agi sci; do
	tree="$out/scummvm-$engine"
	cp -r "$src" "$tree"
	rm -rf "$tree/.git"
	if [ "$engine" = sci ]; then
		# fontchinese 是新增檔案，不在 patch 裡。
		cp /workspace/patches/fontchinese.cpp /workspace/patches/fontchinese.h \
			"$tree/engines/sci/graphics/"
	fi
	(
		cd "$tree"
		patch -p1 < "/workspace/patches/0001-$engine-cht-zh_twn.patch"
		./configure --host=x86_64-w64-mingw32 \
			--disable-all-engines --enable-engine="$engine" \
			--disable-detection-full \
			--with-sdl-prefix="$sdl_prefix"
		# 交叉編譯的產物是 scummvm.exe，沒有名為 scummvm 的 target，用預設 all。
		make -j"$(nproc)"
	)
	cp "$tree/scummvm.exe" "$out/bin/scummvm-pq1-$engine.exe"
	# debug symbol 佔了四分之三體積，交付包不需要（未 strip 的留在 .build-win/）。
	x86_64-w64-mingw32-strip "$out/bin/scummvm-pq1-$engine.exe"
done

# SDL2 是唯一需要隨附的 DLL。ScummVM 的 mingw build 靜態連結了 libstdc++／libgcc／
# winpthread，實測 objdump 的 import table 只有系統 DLL 加 SDL2.dll，所以不必再帶
# 那三個（光 libstdc++-6.dll 就 23 MB）。下面的斷言擋住哪天連結方式改了卻沒發現。
cp "$sdl_prefix/bin/SDL2.dll" "$out/bin/"
for f in "$out"/bin/*.exe; do
	missing=$(x86_64-w64-mingw32-objdump -p "$f" | sed -n 's/.*DLL Name: //p' | sort -u \
		| grep -iE 'libgcc|libstdc|winpthread' || true)
	if [ -n "$missing" ]; then
		echo "$f 需要隨附執行期 DLL：$missing" >&2
		echo "請把它們一併複製到 bin/，否則玩家端會找不到進入點" >&2
		exit 1
	fi
done

# 確認產出的是 Windows PE（MZ 開頭）。
for f in "$out"/bin/*.exe; do
	magic=$(od -An -tx1 -N2 "$f" | tr -d ' \n')
	[ "$magic" = "4d5a" ] || { echo "$f 不是 PE (magic=$magic)" >&2; exit 1; }
	echo "PE ok: $f ($(wc -c < "$f") bytes)"
done

PQ1_REPO_ROOT=/source PQ1_WORKPLACE=/workspace PQ1_DIST_DIR=/workspace/dist-all \
	sh /workspace/tools/assemble_release.sh "$out" windows-x86_64
