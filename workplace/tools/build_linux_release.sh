#!/bin/sh
# 在 pq1-tools 容器內建 Linux 版並組出交付包。
#
#   docker compose -f docker/compose.yml run --rm pq1-tools sh tools/build_linux_release.sh
#
# 預設沿用 .build-{agi,sci}-src 這兩棵已經 configure 過的樹做增量 make（開發中最常用）。
# 帶 --clean 則從 pinned upstream 重新建一份，用來確認交付產物真的可從版控重現。
set -eu

clean=0
[ "${1:-}" = "--clean" ] && clean=1

out=/workspace/.build-linux
rm -rf "$out"
mkdir -p "$out/bin"

if [ "$clean" = 1 ]; then
	src=/workspace/.upstream-src
	sh /workspace/tools/fetch_upstream.sh "$src"
	for engine in agi sci; do
		tree="$out/scummvm-$engine"
		cp -r "$src" "$tree"
		rm -rf "$tree/.git"
		if [ "$engine" = sci ]; then
			cp /workspace/patches/fontchinese.cpp /workspace/patches/fontchinese.h \
				"$tree/engines/sci/graphics/"
		fi
		(
			cd "$tree"
			patch -p1 < "/workspace/patches/0001-$engine-cht-zh_twn.patch"
			./configure --disable-all-engines --enable-engine="$engine" \
				--disable-detection-full
			make -j"$(nproc)" scummvm
		)
		cp "$tree/scummvm" "$out/bin/scummvm-pq1-$engine"
		strip "$out/bin/scummvm-pq1-$engine"
	done
else
	for engine in agi sci; do
		tree="/workspace/.build-$engine-src"
		if [ ! -f "$tree/config.mk" ]; then
			echo "$tree 沒有 configure 過，請改用 --clean" >&2
			exit 1
		fi
		( cd "$tree" && make -j"$(nproc)" scummvm )
		cp "$tree/scummvm" "$out/bin/scummvm-pq1-$engine"
		# debug symbol 不進交付包；未 strip 的留在 .build-<engine>-src/。
		strip "$out/bin/scummvm-pq1-$engine"
	done
fi

# 確認產出的是 Linux ELF（容器裡不一定有 file 指令，改讀 magic）。
for f in "$out"/bin/*; do
	magic=$(od -An -tx1 -N4 "$f" | tr -d ' \n')
	[ "$magic" = "7f454c46" ] || { echo "$f 不是 ELF (magic=$magic)" >&2; exit 1; }
	echo "ELF ok: $f ($(wc -c < "$f") bytes)"
done

PQ1_REPO_ROOT=/source PQ1_WORKPLACE=/workspace PQ1_DIST_DIR=/workspace/dist-all \
	sh /workspace/tools/assemble_release.sh "$out" linux-x86_64
