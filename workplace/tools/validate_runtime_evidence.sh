#!/bin/sh
set -eu

# Run inside pq1-tools. This checks evidence files; it does not claim that a
# screenshot proves an unplayed route. Route provenance remains in the logs.
test -s latest-agi-run.log
test -s latest-sci-run.log
# Entry counts grow with every translation batch, so assert that the loader
# ran and picked up a non-empty table rather than pinning a number that goes
# stale the next time the tables are rebuilt.
grep -Eq 'AGI-CHT: 載入 [1-9][0-9]* 則翻譯' latest-agi-run.log
grep -Eq 'CHT: loaded [1-9][0-9]* translation entries' latest-sci-run.log
grep -F 'Running Police Quest' latest-agi-run.log >/dev/null
grep -F 'Running Police Quest' latest-sci-run.log >/dev/null

for f in \
  captures/pq1-agi-cht-start.png \
  captures/pq1-sci-real-crawl.png \
  captures/pq1-sci-right-hallway.png \
  captures/pq1-sci-locker-room.png \
  captures/pq1-sci-locker-interact.png \
  captures/pq1-sci-locker-after-code.png \
  captures/pq1-sci-locker-stage-open.png \
  captures/pq1-sci-towel2.png
do
  test -s "$f"
done

echo "runtime evidence files and loader logs are present"
