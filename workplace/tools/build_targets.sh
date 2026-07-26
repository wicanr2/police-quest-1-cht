#!/bin/sh
set -eu

# This script is intentionally run from the pq1-tools Docker container.
python3 tools/merge_skeletons.py translation/agi-skeleton.tsv \
  translation/agi-skeleton.tsv extract/agi-object-skeleton.tsv
python3 tools/merge_translation_layers.py translation/agi-skeleton.tsv \
  translation/agi-translation.tsv --batches translation/batch
python3 tools/prefill_exact.py translation/sci-skeleton.tsv \
  /pq2-translation/translation_utf8.tsv /tmp/pq1-sci-prefill.tsv
python3 tools/merge_translation_layers.py translation/sci-skeleton.tsv \
  translation/sci-translation.tsv --base /tmp/pq1-sci-prefill.tsv \
  --batches translation/batch

python3 tools/build_cht.py translation/agi-translation.tsv game/agi \
  --size 15 --font /usr/share/fonts/truetype/arphic/uming.ttc --face 2
python3 tools/build_cht.py translation/sci-translation.tsv game/sci \
  --size 15 --font /usr/share/fonts/truetype/arphic/uming.ttc --face 2
python3 tools/bake_hires_font.py game/agi/pq1_big5_hi.fnt \
  translation/agi-translation.tsv --size 27 --height 28 --width 32 \
  --font /usr/share/fonts/truetype/arphic/uming.ttc --face 2
python3 tools/bake_hires_font.py game/sci/pq1_big5_hi.fnt \
  translation/sci-translation.tsv --size 27 --height 28 --width 32 \
  --font /usr/share/fonts/truetype/arphic/uming.ttc --face 2
python3 tools/build_title_overlay.py agi game/agi/pq1_title.ovl \
  --font /usr/share/fonts/truetype/arphic/uming.ttc --face 2
python3 tools/build_title_overlay.py sci game/sci/pq1_title.ovl \
  --font /usr/share/fonts/truetype/arphic/uming.ttc --face 2

echo "PQ1 targets built: AGI and SCI VGA"
