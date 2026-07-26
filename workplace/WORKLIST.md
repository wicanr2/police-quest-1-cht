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
| M5 macOS 交付 | ✅ | CI run 30206666058 artifact（17 MB），下載後獨立驗證 fat binary 雙弧 |

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
| SCI 訊息框裁切句尾 | `Size()` 量英文、`Box()` 畫中文 | `captures/pq1-sci-m4b-08`（同一畫面對照 `pq1-sci-m4-98`）、`-11`（6 行長句） |

## headless 驗收方法（照做即可，別再自己摸索）

SCI 的開場動畫在 headless 下跳不過去，但 debugger 的 `room` 指令已修成能真正換場，
可從 intro 直接跳進任意合法房間。三個關鍵點（來源：kb `retro-avg-taiwanese-localization`）：

1. **Xvfb 沒有 window manager**，`xdotool` 全域送事件無效。要
   `WID=$(xdotool search --class scummvm | head -1)`，之後一律 `--window "$WID"`。
2. **合法房號**看 `extract/dump-sci/script.*` 的編號，跳不存在的會 fatal 直接關遊戲。
   遊戲場景集中在 10–67，另有 117、134、141、151–160 等。
3. **同一個遊戲行程只能跳一次房**。跳第二次會 `GfxPorts::kernelSetActive was requested
   to set invalid port id 3!` 然後黑屏。每換一個目標房間就重啟一次行程。

進到房間後滑鼠完全正常（左右鍵、look／walk／hand 游標切換、物件互動都可用），
只有 intro 期間無效。AGI 的 debugger `room` 只改變數不重繪，不能用這招，得實際走位；
建議走到定點後存檔，之後用 `--save-slot=N` 當 checkpoint。

## 待驗收項目

1. SCI 的 CHIPSTER 2000 電腦查詢畫面（`警徽 :`／`單位 :`／`姓名 :` 欄位標籤的排版）。
   內容在 `message.117`，room 117 是合法房號但這輪沒跳（給 agent 的清單漏列）。
2. SCI 的 Dooley 簡報、Laura Watts、Jack Cobb 對話、失敗結局／死亡畫面。
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

## 交付包驗證紀錄

三個包都是「解開後在自己的環境驗」，不是只看 build 綠燈：

| 平台 | 驗證內容 |
|---|---|
| Linux | 解包實跑兩個 binary，log 出現 `AGI-CHT: 載入 2816 則翻譯`、`CHT: loaded 3566 translation entries`，截圖中文無缺字 |
| Windows | `objdump` 確認 import 只有系統 DLL 加 SDL2.dll、已 strip；Wine 實跑 AGI 版，翻譯載入數相同 |
| macOS | 下載 artifact 後自行解析 Mach-O fat header：兩個 binary 各有 x86_64 與 arm64 兩個 slice |

三個包都通過 `SHA256SUMS` 校驗（0 失敗）與 patch-only 邊界掃描（無 `RESOURCE.*`／
`VOL.*`／DOS 執行檔／ROM／zip）。

## 建置流程

- Linux：`docker compose -f docker/compose.yml run --rm pq1-tools sh tools/build_linux_release.sh`
- Windows：`docker compose -f docker/compose.yml run --rm pq1-mingw sh tools/build_windows_release.sh`
- macOS：`gh workflow run build-cht-packages.yml`（Apple SDK 不能在 Linux 上交叉編譯）
