# PQ1 繁中化交接記錄

所有建置與驗收均在 `pq1-tools` Docker container 內完成。

## 目前可重建

- AGI Floppy DOS：2,816／3,177 筆，Big5 與 hi-res 字型已產生。
- SCI VGA Remake：3,566／3,667 筆，Big5 與 hi-res 字型已產生。
- 兩版 headless loader、placeholder、Big5 validator 均通過（0 errors）。
- 未翻鍵的分類與理由見 `WORKLIST.md`，全數是引擎符號或刻意保留的專名／代號。

## 本輪修掉的引擎缺陷

AGI 的 `GfxMgr::loadChtResources()` 原本用 `loadPrefixedRaw(fontFile, 16)` 讀字型，但
`tools/build_cht.py --size 15` 產生的 `pq1_big5.fnt` 每字只有 15 列。`loadPrefixedRaw`
按 `2 + height*2` bytes 逐筆讀，高度對不上就逐筆錯位，只有偶然對齊的字查得到 glyph，
其餘畫成空白（狀態列「得分：0 / 245」只顯示得出「得」）。SCI 端的 `GfxFontChinese`
一直是 15，所以只有 AGI 中招。已把 AGI 改成 15 並重編 binary，patch 檔同步更新且
`patch -p1 --dry-run` 對 upstream 乾淨套用。

同時，字型字集原本只從譯文 value 收集，漏掉只出現在引擎硬寫 UI 字串裡的字（如「擇」）。
`build_cht.py` 與 `bake_hires_font.py` 已加 `ENGINE_UI_CHARS` 一律補烘，四個字型檔皆已驗證無缺字。

## 驗收證據

- AGI：`captures/pq1-agi-fontfix-*.png` — 狀態列「得分：0 / 245」「聲音：開」與警局走廊
  中文訊息框皆完整渲染，逐格墨點掃描無空白格。
- SCI：`captures/pq1-sci-v2-*.png` — 主選單中文與修復前逐字一致，無回歸。
- loader 實測：`AGI-CHT: 載入 2816 則翻譯`、`CHT: loaded 3566 translation entries`。

## 下一步

沿 `CLAUDE-PQ1.md` 的 M4～M6 continue：NPC 對話、案件證物操作、失敗結局與 credits 的
逐項 A/B 截圖，以及 Windows／macOS artifact。目前的 patch-only 包尚不可當成最終發布版。
