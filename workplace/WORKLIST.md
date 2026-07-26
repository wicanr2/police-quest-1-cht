# 警察故事 1《追捕死亡天使》中文化工作清單

| 里程碑 | 狀態 | 證據 |
|---|---|---|
| M0 版本辨識 | ✅ | `docs/m0-inventory.md`、`docs/checksums.sha256`、Docker detector output |
| M1 AGI 抽字骨架 | ✅ | `translation/agi-skeleton.tsv`，3,177 keys（含 OBJECT 名稱） |
| M1 SCI 抽字骨架 | ✅ | `translation/sci-skeleton.tsv`，3,667 keys；另抽出 15 筆 script 字串 |
| M2 引擎繪字與字型 | ✅ | Docker 內 AGI/SCI 專用 binary；Big5/hi-res 字型；四個字型均含引擎硬寫 UI 字 |
| M3 翻譯與完整性 | ✅ | AGI 2,816／3,177、SCI 3,566／3,667；validator 0 errors |
| M4 正常流程驗收 | ⏳ | AGI 狀態列／訊息框、SCI 主選單／開場旁白已實機驗證；NPC 對話、案件證物、失敗結局與 credits 仍待逐項截圖 |
| M5 三平台交付 | ⏳ | Linux patch-only 包已可重建；Windows／macOS artifact 未做 |

## 翻譯覆蓋率說明

未翻鍵已全數分類確認，不是漏譯：

- AGI 未翻 361 = 引擎 opcode／parser 詞彙 207（`new.room`、`draw.pic`、`taxi` 等，
  抽字工具誤抽，翻了也不會顯示）+ 刻意保留英文 154（人名、地址、車牌、VIN、分隔線）。
- SCI 未翻 101 = 引擎內部符號 8 + 刻意保留英文 93（人事名冊姓名、除錯字串、
  檔名樣式、抽字工具抽到的二進位殘留）。

## 已知限制與待驗項目

- AGI 資料表把部分長句拆成多個 key（通緝單、逮捕摘要、報紙剪報、方位／速度模板），
  逐行翻譯後的串接語序只能靠實機畫面確認。
- AGI 撲克牌型字串用 `\n` 硬拆詞配合 UI 版位（`Three of\na kind` → `三\n條`），排版待實機確認。
- SCI skeleton 含少量抽字雜訊（二進位殘留字串），已保留原文不譯。

## 版本隔離

- AGI：`original/agi`、`translation/agi-*`、`build/agi-*`
- SCI VGA：`original/vga`、`translation/sci-*`、`build/vga-*`
- 原始 `RESOURCE.*`、`VOL.*`、DOS executable、防拷答案與 ROM 不進 Git。
