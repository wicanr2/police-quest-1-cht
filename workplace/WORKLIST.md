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

整套流程已固化成 `tools/capture_sci_room.sh`（可帶額外點擊座標，例如
`sh tools/capture_sci_room.sh <binary> 117 <out.png> 400,33 110,182` 會進 CHIPSTER
再點 PERSONNEL 與名單第四列）。裡面處理掉的四個坑：

1. **Xvfb 沒有 window manager**，`xdotool` 全域送事件無效。要
   `WID=$(xdotool search --class scummvm | head -1)`，之後一律 `--window "$WID"`。
2. **Xvfb 起來後要暖機約 10 秒**才收得到鍵盤事件。太早送 `ctrl+alt+d`，console 不會開，
   畫面停在標題卡，看起來像「`room` 指令沒作用」，實際上鍵根本沒進去。
3. **換完場要先 `exit` 離開 console**，否則截到的是被 console 蓋住的畫面。
4. **同一個遊戲行程只能跳一次房**。跳第二次會 `GfxPorts::kernelSetActive was requested
   to set invalid port id 3!` 然後黑屏。每換一個目標房間就重啟一次行程。

合法房號看 `extract/dump-sci/script.*` 的編號，跳不存在的會 fatal 直接關遊戲。
遊戲場景集中在 10–67，另有 117、134、141、151–160 等。

進到房間後滑鼠完全正常（左右鍵、look／walk／hand 游標切換、物件互動都可用），
只有 intro 期間無效。AGI 的 debugger `room` 只改變數不重繪，不能用這招，得實際走位；
建議走到定點後存檔，之後用 `--save-slot=N` 當 checkpoint。

## 待驗收項目

1. SCI 的 Dooley 簡報、Laura Watts、Jack Cobb 對話、失敗結局／死亡畫面。
2. AGI 的置物櫃密碼 269 流程、交通攔查、撲克牌局未走到。
3. AGI 跨 key 拼接句（通緝單、逮捕摘要、報紙剪報、方位／速度模板）的串接語序，
   已驗證的部分（失竊車輛播報）通順，其餘待確認。
4. AGI 撲克牌型用 `\n` 硬拆詞配合 UI 版位（`Three of\na kind` → `三\n條`），排版待確認。

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

第一版推完後五列版的「狀態」會壓到藍色分隔線（五列中文要 75px，第一列到分隔線只有
59px）。解法是**整組往上借空間**：中文每列比拉丁行距多佔 5px、最多五列，所以往上移
20px，原版在區塊上緣留的餘裕剛好夠。lift 要套用到整組每一列（含第二欄），
只移第一列會讓兩欄不對齊。現在五列都在分隔線以上，兩欄對齊。

## 待辦：SCI 對話框沒有 CJK 避頭尾（kinsoku）

收尾標點會落在行首，例如 `captures/pq1-sci-m4b-16-room38-bartender-bobby.png` 的
「致命宿醉製造機」，結尾的 `」` 被斷到下一行開頭。不影響閱讀，但排版不正規。

`GfxText16::GetLongest()` 本來就有一套 PC-98 SJIS 的 kinsoku（含標點 seek-back），
但 ZH_TWN 分支**刻意跳過它**——原註解說那套會 over-pack 一個雙位元組字，使置中文字的
`(width - textWidth)/2` 變負數，把行首第一個字推出框外、裁掉左偏旁（你→尔、據→豦）。

要修的話得為 ZH_TWN 寫一套「只做避頭尾、不 over-pack」的版本：斷點若落在禁則字元
（`」』）。，、；：？！` 等）之前，就把前一個字一起推到下一行。要注意連續禁則字元
不能無限回退，且必須保證換行有進度。動的是斷行核心，所有對話框都會受影響，
改完要重跑一輪畫面驗收。

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

## 防拷（copy protection）現況

2026-07-30 重查結論：

- **AGI 原版沒有防拷檢查。** ScummVM AGI 的 `copy_protection` 選項只在 `cycle.cpp`
  被《Gold Rush!》讀取（room 125 ↔ 73），`detection_tables.h` 裡標 `_CP` 的也只有
  `goldrush`；PQ1 的 DOS 條目用 `GAMEOPTIONS_DEFAULT`。抽字表裡也找不到任何
  「documentation／manual」型的關卡字串。無線電通報由 parser 動詞觸發、遊戲自己組句。
- **VGA 版有，而且不是可略過的關卡。** `message.200`（結局訊息庫）裡有
  `This game upholds the law, partner. Come back when you find your documentation.`
  ——這是查手冊型防拷的失敗結局。條號在通報案件與開單時要用，等於綁在主要玩法裡。
  ScummVM SCI 沒有 `copy_protection` 選項，`script_patches.cpp` 的 `pq1vgaSignatures`
  也沒有相關 patch，所以無從「關閉」。玩家要自備原版說明書。
- **條號表改為隨包附上（2026-07-30 使用者決定）。** 原本禁列，理由是沒有條號玩不完，
  而條號是說明書上的參考資料、不是遊戲程式碼或美術。中譯版在 `docs/中文條號速查.md`，
  `assemble_release.sh` 會複製進交付包的 `docs/`。`CLAUDE.md` 的邊界條款已同步改成
  「單點例外」，其餘防拷／破解素材照舊不收——原始 `SENHAS.TXT` 與
  `protections/PQ1 VGA Codes.txt` 仍隨 `workplace/original/` 被 gitignore 擋著。
- **遊戲內指路。** `translation/batch/310-sci-code-hints.tsv` 在四句代碼相關對白後面
  加了指路（三句指向速查表，拘留所問醉漢罪名那句直接標「酒後駕車 21603」）。
  放在 batch 層是因為 `sci-translation.tsv` 每次都由 skeleton + batch 重新合成，
  直接改檔會在下次 `build_targets.sh` 被蓋掉。
  ⚠ 21603 是從遊戲自己的對白推的（Paul 說法官對 DUI 沒耐性、嫌犯「喝得很茫」），
  沒有實機驗過——room 35 要有押解狀態才進得去，debugger 跳不進去。

## 版本隔離

- AGI：`original/agi`、`translation/agi-*`、`.build-agi-src`
- SCI VGA：`original/vga`、`translation/sci-*`、`.build-sci-src`
- 原始 `RESOURCE.*`、`VOL.*`、DOS executable、防拷答案與 ROM 不進 Git。

## 交付包驗證紀錄

三個包都是「解開後在自己的環境驗」，不是只看 build 綠燈：

| 平台 | 驗證內容 |
|---|---|
| Linux | 解包實跑兩個 binary，log 出現 `AGI-CHT: 載入 2816 則翻譯`、`CHT: loaded 3566 translation entries`，截圖中文無缺字；另用**包內**的 SCI binary 跳 room 117 點出人事記錄，確認 CHIPSTER 五列排版修正確實在出貨檔裡 |
| Windows | `objdump` 確認 import 只有系統 DLL 加 SDL2.dll、已 strip；Wine 實跑 AGI 版，翻譯載入數相同 |
| macOS | 下載 artifact 後自行解析 Mach-O fat header：兩個 binary 各有 x86_64 與 arm64 兩個 slice |

三個包都通過 `SHA256SUMS` 校驗（0 失敗）與 patch-only 邊界掃描（無 `RESOURCE.*`／
`VOL.*`／DOS 執行檔／ROM／zip）。

## 建置流程

- Linux：`docker compose -f docker/compose.yml run --rm pq1-tools sh tools/build_linux_release.sh`
- Windows：`docker compose -f docker/compose.yml run --rm pq1-mingw sh tools/build_windows_release.sh`
- macOS：`gh workflow run build-cht-packages.yml`（Apple SDK 不能在 Linux 上交叉編譯）

### VGA 完整包（本機限定）

`tools/assemble_full.sh <build_dir> <platform>` 組出解開就能玩的 VGA 版：patch-only 的
中文資料與 binary，加上 `original/vga` 的 `RESOURCE.*`／`MESSAGE.MAP`，另附啟動腳本
（`開始遊戲.sh`／`.bat`）與條號速查。AGI 的 binary 會被移除——完整包裡沒有對應的 AGI
資料，帶著只會讓人誤會。

**產物不進 Git、不上 Release。** 腳本硬性要求輸出落在 `dist-all/`（`.gitignore` 第 8 行
擋著），repo 裡留的是腳本本身，讓「rebuild 出得來、有紀錄可查」。patch-only 的
`assemble_release.sh` 有一段禁列掃描會擋下 `RESOURCE.*`，這支刻意不掃，差別就在這裡。

    docker compose -f docker/compose.yml run --rm pq1-tools sh -c '
      PQ1_REPO_ROOT=/source PQ1_WORKPLACE=/workspace PQ1_DIST_DIR=/workspace/dist-all \
      sh /workspace/tools/assemble_full.sh /workspace/.build-linux linux-x86_64'

三平台實測產出 14.2／19.8／21.4 MB（Linux／macOS／Windows）。Linux 包解到乾淨目錄後
用包內的 `開始遊戲.sh` 實跑通過，log 出現 `CHT: loaded 3566 translation entries`，
中文標題疊圖正常。
