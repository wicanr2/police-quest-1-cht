#!/bin/sh
# 建一個 engine × 一個 arch 的 macOS ScummVM。
#
#   用法：build_macos_arch.sh <engine> <arch> <src> <tree> <sdl_prefix>
#
# 呼叫端負責決定要不要走 Rosetta：
#   arm64 ： /bin/sh  tools/build_macos_arch.sh agi arm64  ...
#   x86_64： arch -x86_64 /bin/sh tools/build_macos_arch.sh agi x86_64 ...
#
# x86_64 弧非得整個包在 `arch -x86_64` 底下不可。ScummVM 的 configure 是用 uname
# 判 _host_cpu 來決定要不要開 ARM NEON，只在 CXXFLAGS 給 -arch x86_64 它並不知道，
# 在 Apple Silicon runner 上仍會判成 aarch64 而把 graphics/blit/blit-neon.cpp 排進
# x86_64 build；clang 對非 ARM target 的 arm_neon.h 會直接 #error，整輪編譯失敗。
# 走 Rosetta 讓 uname 回報 x86_64，NEON 關掉、SSE2/AVX2 也才會被正確打開。
set -eu

engine=$1
arch=$2
src=$3
tree=$4
sdl_prefix=$5

min_version=11.0

rm -rf "$tree"
cp -r "$src" "$tree"
rm -rf "$tree/.git"

if [ "$engine" = sci ]; then
	# fontchinese 是新增檔案，不在 patch 裡。
	cp "$(dirname "$0")/../patches/fontchinese.cpp" \
	   "$(dirname "$0")/../patches/fontchinese.h" \
	   "$tree/engines/sci/graphics/"
fi

cd "$tree"
patch -p1 < "$(dirname "$0")/../patches/0001-$engine-cht-zh_twn.patch"

# ScummVM 的 configure 是手寫 shell script 不是 autoconf：CXXFLAGS／LDFLAGS 只能走
# 環境變數，當位置參數傳會直接 unrecognized option。
# 停掉所有外部 codec：Homebrew 在 Apple Silicon runner 上只裝 arm64 版，configure
# 即使跑在 Rosetta 下仍會偵測到 /opt/homebrew 的 libjpeg／libpng 並連進去，x86_64
# 弧就會 "found architecture 'arm64', required architecture 'x86_64'" 連結失敗。
# AGI 與 SCI 只需要 SDL2，音樂走內建的 AdLib／MT-32 合成器，這些庫本來就用不到。
CXXFLAGS="-arch $arch -mmacosx-version-min=$min_version" \
LDFLAGS="-arch $arch -mmacosx-version-min=$min_version" \
	./configure --disable-all-engines --enable-engine="$engine" \
		--disable-detection-full \
		--with-sdl-prefix="$sdl_prefix" \
		--disable-jpeg --disable-png --disable-gif \
		--disable-flac --disable-mad --disable-vorbis --disable-tremor \
		--disable-theoradec --disable-mpeg2 --disable-a52 --disable-faad \
		--disable-fluidsynth --disable-freetype2 --disable-libcurl --disable-sdlnet

# 確認 configure 對這一弧的判定真的對了，別等 20 個 uint32x4_t 錯誤才發現。
if [ "$arch" = x86_64 ] && grep -q '^ENABLE_EXT_NEON' config.mk 2>/dev/null; then
	echo "configure 在 x86_64 弧仍啟用了 NEON —— Rosetta 沒生效？" >&2
	exit 1
fi

make -j"$(sysctl -n hw.ncpu)" scummvm
