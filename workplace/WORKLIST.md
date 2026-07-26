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
| SCI 死亡畫面「重新開始」按鈕被切 | 按鈕寬度是為英文 `RESTART` 設計的，4 個全形字放不下 | 譯文改「重來」與另兩個按鈕一致，`captures/pq1-sci-m4c-08` |

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

## 已解決：CHIPSTER 2000 查詢畫面欄位重疊

修法照使用者的方向：**不縮字，改在 640×400 的 display 空間重新排版**
（`rulebook/81` 的鐵則）。在 `GfxPaint16::kernelDisplay()` 加防重疊——某列的文字框
會撞到先前的框時就往下推。三個關鍵細節：

1. **要保留多個框，不能只記上一個**。這畫面左右欄交錯繪製（姓名→性別→警徽→
   D.O.B.→…），上一個框通常是另一欄，比了等於沒比。現在保留最近 12 個。
2. **順序要用 script 指定的原始 y，不能用推完的位置**。用推後的位置判斷「誰在下面」，
   會讓已被推下去的那列看起來比後來的列還低，後者就不推了——清單畫面因此出現兩筆
   姓名疊在同一列。現在 `ChtTextSlot` 同時記 `rect`（碰撞用）與 `scriptTop`（順序用）。
3. **只對 `標籤 : 值` 這種欄位式排版生效**。20 列的人事名單用完全相同的行距，但
   20 列中文需要 300px、畫面只有 200px，推擠只會把前段推散、後段仍疊著。兩者用幾何
   分不開，欄位分隔符才分得開。

證據：`captures/pq1-sci-m4f-01-chipster-5rows.png`（五列版，含「狀態」）、
`captures/dbg-chipster.png`（四列版），對照修正前的 `pq1-sci-m4c-01`。

**殘留的小瑕疵**：五列版的「狀態」會被推到略低於藍色分隔線。五列中文需要 75px，
而分隔線以上放不下——這是原版版面的硬限制，不縮字就解不掉。文字完全可讀，
相比原本糊成一團可接受。

## 已知限制（不必再查）：人事名單畫面

PERSONNEL 名單 20 列用 10px 行距，中文放不下（需要 300px、畫面 200px），
維持原樣不動。另外名單本身有兩個與中文化無關的既有問題：每隔幾列會有兩筆姓名
疊在同一列（資料索引重複），以及點擊命中判定固定比視覺位置多一列。

## 舊記錄（已解決，保留脈絡）：CHIPSTER 2000 查詢畫面欄位重疊

`captures/pq1-sci-m4c-01-chipster-personnel-dinkle.png`。人事／車籍查詢畫面（room 117）
的欄位標籤上下相鄰列**垂直重疊**，「姓名／警徽／D.O.H./單位／狀態」筆畫互相黏連，
`D.O.H.` 幾乎被夾到看不清。右欄「性別／D.O.B./身高／體重」同樣。

根因是原版 UI 用 `kDisplay` 在絕對座標逐行畫字，行距按 8px 拉丁字型排的（約 10 邏輯
像素），而中文 hi-res 字高 28 display 像素（14 邏輯像素）→ 溢出行高。這條路徑不經過
`Box()`，所以不像對話框那樣會依字高自動撐開行距。

查嫌犯與車牌是 PQ1 的核心玩法，不算次要畫面。三個可能方向，都有代價，**待決定**：

1. **縮小中文字高**到 ≤20 display 像素。違反 `rulebook/81`（CJK 不縮字）的鐵則，
   且會讓全遊戲的中文一起變小。
2. **這個畫面的欄位標籤保留英文**（`NAME :`／`BADGE :`），只翻譯值。純翻譯改動、零引擎
   風險，但只解掉一半（`單位: 證物組`、`狀態: 現役` 兩行的值仍是中文高度），
   且降低中文化完整度。
3. **在引擎端針對這條 `kDisplay` 路徑重新分配 y 座標**。能真正解決，但要判斷「哪些列
   屬於同一組欄位」，改動複雜且容易波及其他用 `kDisplay` 的畫面。

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
