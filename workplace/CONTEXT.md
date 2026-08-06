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
- **[HARD] 逐位元組掃描字串的地方一律先認 Big5 lead byte（0x81-0xFE）**。Big5 的 trail
  byte 落在 `0x40-0x7E` 時會撞 `\`(0x5C)——「許功蓋擺餐枯閱髏」的第二個 byte 就是它。
  v1.0.2 修的就是這個：`TextMgr::stringPrintf()`（AGI 的 `%` 格式展開器，所有訊息必經）
  逐 byte 掃描、遇 `\` 就跳過，把半個中文字吃掉，整串往後錯位到遇上單位元組 ASCII 才
  重新同步。**那是 ScummVM 上游原生碼**——自己加的 Big5 判定（繪字、欄寬、選單欄寬）
  當初都做了，上游的不會自己浮出來，動手前 grep 一次 `case '\\'`、`== '\\'`。
  SCI 的 `unescapeCht()` 有同型缺口（trail `0x5C` 後緊接 `n`/`t`/`\` 才中），
  PQ1 目前 0 則觸發，已一併加固。

## 回歸測試:`cht_selftest`

`[pq1]` 加 `cht_selftest=true`，啟動時把每則譯文餵進 `stringPrintf` 走一遍，
檢查其中的 Big5 字序列有沒有被改掉：

```
AGI-CHT-SELFTEST: 檢查 2552 則(跳過含 % 的 264 則);
                  舊行為會壞 58 則(正對照),目前 Big5 序列被改動 0 則
```

兩件事別改壞：

- **判定用 Big5 字序列比對，不是「輸出 == 輸入」**。AGI 訊息裡 `\` 是真的跳脫字元，
  PQ1 報紙畫面合法地用 `\|` 當換行標記（63 則），整串比對會把它們誤報成缺陷。
- **正對照（「舊行為會壞 N 則」）要留著**。只報 0 分不出「修好了」與「根本沒測到東西」。

## 未完成事項

1. M4 逐項實機驗收：NPC 對話、案件證物操作、失敗結局、credits 的中英 A/B 截圖。
2. AGI 跨 key 拼接句（通緝單、逮捕摘要、報紙剪報、方位模板）的串接語序實機確認。
3. AGI 撲克牌型 `\n` 硬拆詞的排版確認。
4. Windows／macOS artifact 與三平台打包驗證。
5. 只打包 patch、字型、翻譯、建置說明與 checksum，不帶入原始遊戲資源。
