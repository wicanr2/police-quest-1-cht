#!/bin/sh
# 用 ScummVM 的 MT-32 模擬（munt + 原版 ROM）實錄遊戲配樂，給推廣片用。
#   record_mt32.sh <out.raw> <sound 資源編號...>
#   SONGLEN=<秒> 可調每首錄多久（預設 14）
#
# 兩個前提：
# 1. MT-32 ROM 要跟中文資料放在同一個 extrapath（ScummVM 只吃一個），先把
#    MT32_CONTROL.ROM／MT32_PCM.ROM 複製到 out/promo/extra/。ROM 不進 Git。
# 2. 用 SDL_AUDIODRIVER=disk 實錄，不要設 SDL_DISKAUDIODELAY=0——全速跑會讓 SCI
#    排序器近乎靜音（CLAUDE.md §8 記過這個坑）。
#
# 產出是裸 s16le 44100 立體聲，用 ffmpeg -f s16le -ar 44100 -ac 2 轉 wav。
# PQ1 VGA 實測：sound 82 與 86 有音樂，其餘多半靜音；遊戲場景本身幾乎不放配樂，
# 所以片頭主題要另外從遊戲啟動的前 20 秒錄。
set -eu
out=$1; shift
export DISPLAY=:91
Xvfb :91 -screen 0 1024x768x24 >/dev/null 2>&1 & sleep 10
export SDL_AUDIODRIVER=disk SDL_DISKAUDIOFILE="$out"
cfg=/tmp/rs.ini; rm -f "$cfg"
B=/workspace/.build-linux/bin/scummvm-pq1-sci
$B --config=$cfg --add --path=/workspace/original/vga >/dev/null 2>&1
$B --config=$cfg --extrapath=/workspace/out/promo/extra --language=tw \
  --music-driver=mt32 --output-rate=44100 pq1sci >/tmp/rs.log 2>&1 &
game=$!
sleep 22
WID=$(xdotool search --class scummvm | head -1)
i=0
for id in "$@"; do
  xdotool key --window "$WID" ctrl+alt+d; sleep 2
  xdotool type --window "$WID" --delay 50 "startsound $id"; xdotool key --window "$WID" Return
  echo "slot $i -> sound $id"
  sleep ${SONGLEN:-14}
  i=$((i+1))
done
kill $game 2>/dev/null || true
