# PQ1 中文化目前上下文

- 遊戲：Police Quest: In Pursuit of the Death Angel
- 目標語言：台灣繁體中文，執行期 Big5
- 已確認原版 Floppy DOS 是 AGI；VGA Remake 是 SCI。
- Docker detector 已確認：`agi:pq1` = AGI 2.0G 1987-12-03；`sci:pq1sci` = SCI/DOS/English。
- 來源 archive 的 SHA-256 見 `docs/checksums.sha256`。
- 所有 ScummVM build、dump、headless 測試均須由 Docker 執行；本機只保存來源碼、腳本與產物。
- Docker 內已建立兩個分離執行檔：`build/scummvm-pq1-agi` 與 `build/scummvm-pq1-sci`。
- 進度數字（覆蓋率、翻譯筆數）以 `WORKLIST.md` 為單一真相，本檔不複製。

## 翻譯 pipeline

`translation/batch/*.tsv`（版控來源，英文 key + 繁中 value）
→ `tools/merge_translation_layers.py` 疊到 skeleton
→ `tools/build_cht.py` 產 runtime Big5 tsv 與 `pq1_big5.fnt`
→ `tools/bake_hires_font.py` 產 640×400 用的 `pq1_big5_hi.fnt`
→ `tools/build_title_overlay.py` 產標題疊圖

新增批次的流程：`tools/prep_pending_batches.py` 切未翻鍵 → 譯者依
`translation/LOCALIZE_INSTRUCTIONS.md` 產出 → `tools/verify_batch.py` 逐行核 key／
placeholder／Big5 → 收進 `translation/batch/` → `tools/normalize_names.py` 收斂譯名。

## 硬性約定

- 專有名詞（人名、地名、店名、街名）保留英文原文，只譯通用字尾；譯名定案表在
  `translation/LOCALIZE_INSTRUCTIONS.md`，`translation/glossary.tsv` 是其摘要。
- Big5 字型的高度必須與引擎 `loadPrefixedRaw` 的 height 相同（目前兩版都是 15），
  對不上會逐筆錯位、大量缺字。
- 引擎硬寫的 UI 字串不在 translation.tsv 裡，其用字由 `build_cht.py` 的
  `ENGINE_UI_CHARS` 補烘進字型。

## 未完成事項

1. M4 逐項實機驗收：NPC 對話、案件證物操作、失敗結局、credits 的中英 A/B 截圖。
2. AGI 跨 key 拼接句（通緝單、逮捕摘要、報紙剪報、方位模板）的串接語序實機確認。
3. AGI 撲克牌型 `\n` 硬拆詞的排版確認。
4. Windows／macOS artifact 與三平台打包驗證。
5. 只打包 patch、字型、翻譯、建置說明與 checksum，不帶入原始遊戲資源。
