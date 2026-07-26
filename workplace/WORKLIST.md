# 警察故事 1《追捕死亡天使》中文化工作清單

| 里程碑 | 狀態 | 證據 |
|---|---|---|
| M0 版本辨識 | ✅ | `docs/m0-inventory.md`、`docs/checksums.sha256`、Docker detector output |
| M1 AGI 抽字骨架 | ✅ | `translation/agi-skeleton.tsv`，3,177 keys（含 OBJECT 名稱） |
| M1 SCI 抽字骨架 | ✅ | `translation/sci-skeleton.tsv`，3,667 keys；另抽出 15 筆 script 字串 |
| M2 引擎繪字與字型 | ✅ | AGI/SCI 專用 binary；Big5／hi-res 字型；四個字型檔均含引擎硬寫 UI 字 |
| M3 翻譯與完整性 | ✅ | AGI 2,816／3,177、SCI 3,566／3,667；validator 0 errors |
| M4 正常流程驗收 | ⏳ | AGI 已驗；SCI 部分已驗，仍有待驗項目（見下） |
| M5 Linux 交付 | ✅ | `dist-all/pq1-cht-linux-x86_64.tar.gz`（5.9 MB），解包實跑通過 |
| M5 Windows 交付 | ✅ | `dist-all/pq1-cht-windows-x86_64.zip`（20 MB），Wine 實跑通過 |
| M5 macOS 交付 | ⏳ | CI 走 macos-14 universal，NEON 已修，正在解外部 codec 架構問題 |

## 翻譯覆蓋率說明

未翻鍵已全數分類確認，不是漏譯：

- AGI 未翻 361 = 引擎 opcode／parser 詞彙 207（`new.room`、`draw.pic`、`taxi` 等，
  抽字工具誤抽，翻了也不會顯示）+ 刻意保留英文 154（人名、地址、車牌、VIN、分隔線）。
- SCI 未翻 101 = 引擎內部符號 8 + 刻意保留英文 93（人事名冊姓名、除錯字串、
  檔名樣式、抽字工具抽到的二進位殘留）。

## 已修掉的顯示缺陷

| 缺陷 | 根因 | 證據 |
|---|---|---|
| AGI 狀態列只顯示「得」 | `loadPrefixedRaw(fontFile, 16)` 與 15 列字型不符，逐筆錯位 | `captures/pq1-agi-fontfix-*.png` |
| AGI 中英混雜 | `%m`／`%g` 展開子訊息時沒查翻譯表 | `captures/pq1-agi-mfix-02-locker.png` |
| 存讀檔 UI 缺「擇」字 | 字型字集只從譯文收，漏掉引擎硬寫 UI 字串 | `ENGINE_UI_CHARS`，四個字型檔已驗證無缺字 |
| SCI 訊息框裁切句尾 | `Size()` 量英文、`Box()` 畫中文 | 已修，**尚未取得畫面證據**（見下） |

## 待驗收項目

1. **SCI 訊息框裁切修正的畫面證據**。修正已套用（`Size()` 是唯一量測入口，
   `kTextSize` 與 `GfxPaint16` 都經過它），但 headless 容器的滑鼠事件送不進 SCI、
   跳不過開場動畫，三種方式都試過。需要能操作真實滑鼠的環境重跑，對照
   `captures/pq1-sci-m4-99-wall-msg-truncated.png`（修正前只顯示「沒錯，是一」）。
2. SCI 的 NPC 對話（Dooley 簡報、Laura Watts、Jack Cobb）、CHIPSTER 2000 查詢畫面、
   失敗結局／死亡畫面未走到。
3. AGI 的置物櫃密碼 269 流程、交通攔查、撲克牌局未走到。
4. AGI 跨 key 拼接句（通緝單、逮捕摘要、報紙剪報、方位／速度模板）的串接語序，
   已驗證的部分（失竊車輛播報）通順，其餘待確認。
5. AGI 撲克牌型用 `\n` 硬拆詞配合 UI 版位（`Three of\na kind` → `三\n條`），排版待確認。

## 已知限制（非缺工，不必再查）

- SCI 的存讀檔畫面是 ScummVM 自己的 GMM 介面，語言由 ScummVM 的 `translations.dat`
  決定，不在本 patch 管轄範圍。
- SCI 的暫停選單（SAVE/RESTORE/DETAIL/VOLUME/SPEED）與 credits 職銜卡是 baked art，
  不是文字資源，超出文字 hook 範圍。
- SCI 道具欄空的時候顯示 `You are carrying: nothing!`，是引擎硬編碼字串，
  抽字工具沒抓到，屬真實翻譯缺口但需另外 hook。

## 版本隔離

- AGI：`original/agi`、`translation/agi-*`、`.build-agi-src`
- SCI VGA：`original/vga`、`translation/sci-*`、`.build-sci-src`
- 原始 `RESOURCE.*`、`VOL.*`、DOS executable、防拷答案與 ROM 不進 Git。

## 建置流程

- Linux：`docker compose -f docker/compose.yml run --rm pq1-tools sh tools/build_linux_release.sh`
- Windows：`docker compose -f docker/compose.yml run --rm pq1-mingw sh tools/build_windows_release.sh`
- macOS：`gh workflow run build-cht-packages.yml`（Apple SDK 不能在 Linux 上交叉編譯）
