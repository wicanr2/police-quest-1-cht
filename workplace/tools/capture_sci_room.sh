#!/bin/sh
# headless 跳房間截圖，在 pq1-tools 容器內跑。
#   capture_sci_room.sh <binary> <room> <out.png> [x,y ...]
# 例：capture_sci_room.sh /workspace/build/scummvm-pq1-sci 117 /workspace/captures/x.png 400,33 110,182
#
# 四個坑（來源：kb retro-avg-taiwanese-localization，WORKLIST「headless 驗收方法」）：
# 1. Xvfb 沒有 window manager，xdotool 一律要 --window "$WID"。
# 2. Xvfb 起來後要暖機約 10 秒才收得到鍵盤事件。太早送 ctrl+alt+d，console 不會開，
#    畫面停在標題卡，看起來像「room 指令沒作用」——實際上鍵根本沒進去。
# 3. `room` 換完場要先 `exit` 離開 console，否則截到的是 console 蓋住的畫面。
# 4. 同一個行程只能跳一次房，跳第二次會 GfxPorts 失效黑屏——每個目標房重開一次。
set -eu

bin=$1
room=$2
out=$3
shift 3

export DISPLAY=:99
if ! xdotool search --class '' >/dev/null 2>&1; then
	Xvfb :99 -screen 0 1024x768x24 >/dev/null 2>&1 &
	sleep 10
fi

log=$(dirname "$out")/capture-room.log
cfg=/tmp/pq1sci-capture.ini
rm -f "$cfg"
"$bin" --config="$cfg" --add --path=/workspace/original/vga >/dev/null 2>&1
"$bin" --config="$cfg" --extrapath=/workspace/game/sci --language=tw \
       --debugflags=graphics --debuglevel=2 pq1sci >"$log" 2>&1 &
game=$!
sleep 20

wid=""
for _ in 1 2 3 4 5; do
	wid=$(xdotool search --class scummvm | head -1)
	[ -n "$wid" ] && break
	sleep 2
done
[ -n "$wid" ] || { echo "找不到 scummvm 視窗" >&2; kill $game; exit 1; }

xdotool key --window "$wid" ctrl+alt+d
sleep 2
xdotool type --window "$wid" --delay 60 "room $room"
xdotool key --window "$wid" Return
sleep 3
xdotool type --window "$wid" --delay 60 "exit"
xdotool key --window "$wid" Return
sleep 10

# 額外的點擊：進了房間還要操作才會出現的畫面（例如 CHIPSTER 的人事記錄）
for spot in "$@"; do
	xdotool mousemove --window "$wid" "${spot%,*}" "${spot#*,}" click 1
	sleep 6
done

# 游標停在剛點的位置會壓住文字，截圖前先移到角落
xdotool mousemove --window "$wid" 628 470
sleep 1

import -window "$wid" "$out"
kill $game 2>/dev/null || true
echo "captured: $out"
grep -a 'CHT kDisplay' "$log" | head -14 || true
