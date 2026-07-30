#!/bin/sh
# AGI 實機截圖。用法：capture_agi_shot.sh <out.png> [輸入腳本]
#
# 輸入腳本一行一個動作：key <鍵> / type <字串> / click <x> <y> / wait <秒> / shot <檔名>
# `shot` 可在流程中途截，用來一次跑拿到標題與遊戲中兩張。
#
# 坑同 SCI 那支：Xvfb 要暖機約 10 秒才收得到鍵盤；`read` 要用 verb+rest 整段接，
# 拆成 verb a b 會讓 `type look locker` 只打出 look。
set -eu

out=$1
script=${2:-}

export DISPLAY=:85
Xvfb :85 -screen 0 1024x768x24 >/dev/null 2>&1 &
sleep 10

cfg=/tmp/agishot.ini
rm -f "$cfg"
B=/workspace/.build-linux/bin/scummvm-pq1-agi
"$B" --config="$cfg" --add --path=/workspace/original/agi >/dev/null 2>&1
"$B" --config="$cfg" --extrapath=/workspace/game/agi pq1 >/tmp/agishot.log 2>&1 &
game=$!
sleep 14

wid=""
for _ in 1 2 3 4 5; do
	wid=$(xdotool search --class scummvm | head -1)
	[ -n "$wid" ] && break
	sleep 2
done
[ -n "$wid" ] || { echo "找不到視窗" >&2; kill $game; exit 1; }

if [ -n "$script" ] && [ -f "$script" ]; then
	while read -r verb rest; do
		case "$verb" in
		key)   xdotool key --window "$wid" $rest ;;
		type)  xdotool type --window "$wid" --delay 90 "$rest" ;;
		click) xdotool mousemove --window "$wid" $rest click 1 ;;
		wait)  sleep "$rest" ;;
		shot)  import -window "$wid" "$rest"; echo "shot: $rest" ;;
		esac
	done < "$script"
fi

import -window "$wid" "$out"
kill $game 2>/dev/null || true
echo "captured: $out"
