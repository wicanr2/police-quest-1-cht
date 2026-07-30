#!/bin/sh
# 推廣片合成。在 pq1-tools 容器內跑（那個 image 有 ffmpeg 也有 ScummVM 執行期相依）。
#
# 素材來源（rulebook/93：一律用原版真實素材，不自產）：
#   影片 out/promo/clips/*.mp4  —— capture_clip.sh / capture_sci_room.sh 錄的實機畫面
#   配樂 out/promo/audio/*.wav  —— ScummVM 的 MT-32 模擬（munt + 原版 ROM）以
#                                  SDL_AUDIODRIVER=disk 實錄，不是自己合成的逼近音色
#
# 依 kb game-promo-video-ffmpeg：不用 zoompan（幀數會爆炸），靜態卡 + fade 就夠；
# 全部 -preset veryfast -threads 2。
set -eu

# ── 設計 token（換遊戲只改這幾行）───────────────────────────────
W=640; H=480; FPS=15
FONT=/usr/share/fonts/opentype/noto/NotoSerifCJK-Bold.ttc
BG=black
FG=white
ACCENT=0xE8C36A          # 警徽金
TITLE='警察故事 1：追捕死亡天使'
SUB='繁體中文化'
REPO='github.com/wicanr2/police-quest-1-cht'
# ───────────────────────────────────────────────────────────────

root=${PQ1_PROMO_ROOT:-/workspace/out/promo}
clips=$root/clips
audio=$root/audio
work=$root/work
out=${1:-$root/pq1-cht-promo.mp4}
mkdir -p "$work"

esc() { printf '%s' "$1" | sed "s/:/\\\\:/g; s/'/\\\\\\\\'/g"; }

# card <輸出> <秒數> <主字> <副字> [主字級，預設 40]
# 片尾的 repo 網址用 40 級會超出 640 寬被切掉左右兩端，所以字級要能個別指定。
card() {
	o=$1; s=$2; t=$(esc "$3"); u=$(esc "$4"); ts=${5:-40}
	ffmpeg -y -f lavfi -i "color=c=$BG:s=${W}x${H}:d=$s:r=$FPS" \
		-vf "drawtext=fontfile=$FONT:text='$t':fontcolor=$FG:fontsize=$ts:x=(w-tw)/2:y=(h/2)-56,\
drawtext=fontfile=$FONT:text='$u':fontcolor=$ACCENT:fontsize=26:x=(w-tw)/2:y=(h/2)+8,\
fade=t=in:st=0:d=0.6,fade=t=out:st=$(awk "BEGIN{print $s-0.6}"):d=0.6,format=yuv420p" \
		-t "$s" -r $FPS -c:v libx264 -preset veryfast -threads 2 -pix_fmt yuv420p "$o" \
		>/dev/null 2>&1
}

# seg <輸出> <來源clip> <起點> <秒數> <角落標籤>
seg() {
	o=$1; src=$2; ss=$3; s=$4; lab=$(esc "$5")
	ffmpeg -y -ss "$ss" -t "$s" -i "$src" \
		-vf "scale=${W}:${H},fps=$FPS,\
drawtext=fontfile=$FONT:text='$lab':fontcolor=$ACCENT:fontsize=20:x=16:y=h-52:\
box=1:boxcolor=black@0.75:boxborderw=8,\
fade=t=in:st=0:d=0.4,fade=t=out:st=$(awk "BEGIN{print $s-0.4}"):d=0.4,format=yuv420p" \
		-r $FPS -c:v libx264 -preset veryfast -threads 2 -pix_fmt yuv420p -an "$o" \
		>/dev/null 2>&1
}

echo "1/4 標題與字卡"
card "$work/01-title.mp4" 4.0 "$TITLE" "$SUB"
card "$work/03-mid.mp4"   2.5 "兩個版本都做" "1987 AGI／EGA　·　1992 VGA Remake"
card "$work/06-end.mp4"   5.0 "$REPO" "patch-only．原始遊戲資料請自備" 24

echo "2/4 實機片段"
seg "$work/02-agi.mp4"     "$clips/agi.mp4"          8  16 "原版 1987　AGI／EGA"
seg "$work/04-street.mp4"  "$clips/sci-street.mp4"   2  14 "VGA Remake 1992"
seg "$work/05-chipster.mp4" "$clips/sci-chipster.mp4" 2  17 "CHIPSTER 2000　查嫌犯與車籍"

echo "3/4 串接"
: > "$work/list.txt"
for f in 01-title 02-agi 03-mid 04-street 05-chipster 06-end; do
	echo "file '$work/$f.mp4'" >> "$work/list.txt"
done
ffmpeg -y -f concat -safe 0 -i "$work/list.txt" -c copy "$work/video.mp4" >/dev/null 2>&1
vdur=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$work/video.mp4")
echo "    影像長度 ${vdur}s"

echo "4/4 配樂"
# 片頭主題接場景曲，交叉淡入；末尾淡出。loudnorm 讓音量一致（原錄音偏小聲）。
# 片頭主題 18.5s + 場景曲 30.1s ≈ 46.6s，比影像短；場景曲再接一輪湊足長度，
# 交叉淡入銜接。不夠長就被 -shortest 砍掉片尾字卡（第一版就是這樣少了 11 秒）。
ffmpeg -y -i "$audio/title.wav" -i "$audio/theme.wav" -i "$audio/theme.wav" \
	-filter_complex "[0:a]afade=t=in:st=0:d=1[a0];\
[a0][1:a]acrossfade=d=2:c1=tri:c2=tri[m1];\
[m1][2:a]acrossfade=d=2:c1=tri:c2=tri[m2];\
[m2]loudnorm=I=-18:TP=-1.5:LRA=11,afade=t=out:st=$(awk "BEGIN{print $vdur-3}"):d=3[out]" \
	-map "[out]" -t "$vdur" -c:a aac -b:a 192k "$work/music.m4a" >/dev/null 2>&1
adur=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$work/music.m4a")
echo "    配樂長度 ${adur}s"

ffmpeg -y -i "$work/video.mp4" -i "$work/music.m4a" \
	-c:v copy -c:a copy -shortest "$out" >/dev/null 2>&1

echo "promo: $out"
ffprobe -v error -show_entries format=duration,size -show_entries stream=codec_name,width,height \
	-of default=nw=1 "$out"
