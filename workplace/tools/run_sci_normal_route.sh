#!/bin/sh
set -eu

# Run inside pq1-tools.  The original game data is deliberately outside the
# patch package; only the project-owned extra path is added to the target.
config=${1:-/tmp/pq1sci-normal.ini}
if [ "${config#/tmp/}" = "$config" ]; then
	echo "config must be under /tmp" >&2
	exit 2
fi

rm -f "$config"
build/scummvm-pq1-sci --config="$config" --add --path=/workspace/original/vga
exec build/scummvm-pq1-sci \
	--config="$config" \
	--extrapath=/workspace/game/sci \
	--language=tw \
	--debuglevel=1 \
	pq1sci
