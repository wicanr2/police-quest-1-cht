# Docker 執行驗證記錄

所有指令均由 `workplace/docker/compose.yml` 的 `pq1-tools` 容器執行。

## 最近啟動回歸

- AGI：`Running Police Quest: In Pursuit of the Death Angel (2.0G 1987-12-03/DOS/English)`、`AGI-CHT: Big5 字型 pq1_big5.fnt 已載入`、`AGI-CHT: 載入 1314 則翻譯`、`Running AGI script`。
- SCI VGA：`Running Police Quest: In Pursuit of the Death Angel (SCI/DOS/English)`、`CHT: loaded 971 translation entries`。
- 兩個 headless 指令以 timeout 結束，沒有 fatal error；Docker 沒有 ALSA 音效裝置的警告不影響文字 loader。
- `tools/validate_translation.py`：AGI `1,314/3177, 0 errors`；SCI `971/3667, 0 errors`。
- SCI `SCI_LOG_GFX` 實測首張 picture 為 `106`；最新 binary 會記錄 `drawPicture pic=106`，並使用 `game/sci/pq1_title.ovl`。
- AGI 實測載入 `pq1_title.ovl`：`AGI-CHT: 標題疊圖已載入 (376x46 @ 132,320)`。
- `tools/validate_runtime_evidence.sh` 已在 Docker 內通過，確認上述 loader log 與正常流程截圖檔案存在。
- 最新乾淨 target 回歸使用 `--add --path=/workspace/original/vga` 建立 target，再以
  `--extrapath=/workspace/game/sci --language=tw pq1sci` 啟動；已實際點選中文「開始新遊戲」
  並擷取自然 intro（`captures/pq1-normal-natural-30.png` 至 `-140.png`）。

## 截圖

`captures/pq1-agi-cht-start.png`、`captures/pq1-sci-menu-fixedfont.png`、
`captures/pq1-sci-crawl-fixedfont.png` 與 `captures/pq1-sci-menu-english.png` 是 Docker
Xvfb 擷取的 AGI／SCI 中文標題、中文主選單、中文開場旁白與英文同場景 A/B 畫面。
另外 `captures/pq1-sci-right-hallway.png`、`captures/pq1-sci-locker-room.png`、
`captures/pq1-sci-locker-code269.png` 是 SCI 正常點選「開始新遊戲」後進入警局、主走廊、
更衣室並操作置物櫃的實機畫面；其中置物櫃提示與密碼成功訊息已確認為繁中。Dooley／案件證物
的完整正常流程仍待逐步截圖驗收。

## Binary

- 最新 SCI localized binary：`dc22376498c91b853edcadf5bf09a6e82113063bfcf0e2c05689441e4ccc8031`。
- AGI binary：`b3858a495e2c78d6e12313570efc04dea9335811b228312884e1c261b46dd566`。
