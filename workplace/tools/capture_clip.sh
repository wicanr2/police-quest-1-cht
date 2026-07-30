#!/bin/sh
# 錄一段實機遊玩影片。用法：capture_clip.sh <agi|sci> <out.mp4> <秒數> [輸入腳本檔]
#
# 輸入腳本一行一個 xdotool 動作，格式：
#   key <鍵>           送按鍵
#   type <字串>        打字（不含 Enter）
#   click <x> <y>      點座標
#   wait <秒>          等待
#
# 坑同 capture_sci_room.sh：Xvfb 要暖機約 10 秒才收得到鍵盤，xdotool 一律指定 --window。
# Xvfb 必須開 1024x768：開成剛好 640x480 時 debugger console 收不到鍵盤，
# SCI 的換場指令會整段失效（實測 640x480 連兩次都停在標題卡）。x11grab 依視窗座標裁切。
set -eu

engine=$1
out=$2
secs=$3
script=${4:-}
# 錄影前先跑的腳本。SCI 的開場動畫 headless 跳不過去，得先用 debugger 換場；
# 那段 console 畫面不該進推廣片，所以在開錄之前做完。
prescript=${5:-}

export DISPLAY=:90
Xvfb :90 -screen 0 1024x768x24 >/dev/null 2>&1 &
sleep 10

cfg=/tmp/clip-$engine.ini
rm -f "$cfg"
case "$engine" in
agi)
	B=/workspace/.build-linux/bin/scummvm-pq1-agi
	"$B" --config="$cfg" --add --path=/workspace/original/agi >/dev/null 2>&1
	"$B" --config="$cfg" --extrapath=/workspace/game/agi pq1 >/tmp/clip.log 2>&1 &
	;;
sci)
	B=/workspace/.build-linux/bin/scummvm-pq1-sci
	"$B" --config="$cfg" --add --path=/workspace/original/vga >/dev/null 2>&1
	"$B" --config="$cfg" --extrapath=/workspace/game/sci --language=tw pq1sci >/tmp/clip.log 2>&1 &
	;;
*) echo "engine 只能是 agi 或 sci" >&2; exit 2 ;;
esac
game=$!
sleep 24

wid=$(xdotool search --class scummvm | head -1)
[ -n "$wid" ] || { echo "找不到視窗" >&2; kill $game; exit 1; }

run_script() {
	[ -n "$1" ] && [ -f "$1" ] || return 0
	# rest 必須整段接住：早期版本寫成 read -r verb a b，`type room 117` 會被拆成
	# a=room、b=117，只打出 "room"，換場整個失效卻沒有任何錯誤訊息。
	while read -r verb rest; do
		case "$verb" in
		key)   xdotool key --window "$wid" $rest ;;
		type)  xdotool type --window "$wid" --delay 90 "$rest" ;;
		click) xdotool mousemove --window "$wid" $rest click 1 ;;
		wait)  sleep "$rest" ;;
		esac
	done < "$1"
}

run_script "$prescript"

# 先錄影，再送輸入，這樣操作過程整段都在畫面裡
eval "$(xdotool getwindowgeometry --shell "$wid")"
ffmpeg -y -f x11grab -video_size "${WIDTH}x${HEIGHT}" -framerate 15 \
	-i ":90+${X},${Y}" -t "$secs" \
	-c:v libx264 -preset veryfast -threads 2 -pix_fmt yuv420p -an "$out" \
	>/tmp/grab.log 2>&1 &
grab=$!
sleep 1

run_script "$script"

wait $grab || true
kill $game 2>/dev/null || true
echo "clip: $out"
