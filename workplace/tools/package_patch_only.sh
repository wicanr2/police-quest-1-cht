#!/bin/sh
set -eu

# Run inside pq1-tools.  This package deliberately copies only project-owned
# patches, translation data, fonts, and rebuilt engine binaries; original
# RESOURCE/VOL/DOS files are never traversed.
out=${1:-/workspace/dist-all/pq1-cht-patch}
rm -rf "$out"
mkdir -p "$out/patches" "$out/tools" "$out/translation" "$out/game/agi" "$out/game/sci" "$out/bin"

cp -a patches/. "$out/patches/"
cp -a tools/. "$out/tools/"
cp -a translation/*.tsv "$out/translation/"
cp -a game/agi/*.fnt game/agi/*.ovl game/agi/translation.tsv "$out/game/agi/"
cp -a game/sci/*.fnt game/sci/*.ovl game/sci/translation.tsv "$out/game/sci/"
cp -a build/scummvm-pq1-agi build/scummvm-pq1-sci "$out/bin/"
cp /source/README.md "$out/README.md"
cp CONTEXT.md WORKLIST.md "$out/"

find "$out" -type f | sort | while read -r f; do
	case "$f" in
		*/RESOURCE.*|*/VOL.*|*/LOGDIR|*/PICDIR|*/VIEWDIR|*/OBJECT|*/WORDS.TOK|*/INTERP.*|*/MT32.DRV) echo "forbidden file in patch package: $f" >&2; exit 1;;
	esac
done

manifest="$out/SHA256SUMS"
find "$out" -type f ! -name SHA256SUMS -print | sort | xargs sha256sum > "$manifest"
tarball="${out%/*}/$(basename "$out").tar.gz"
tar -C "${out%/*}" -czf "$tarball" "$(basename "$out")"
echo "patch-only package: $tarball"
