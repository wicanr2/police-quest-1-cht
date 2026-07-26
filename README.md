# 《警察故事 1：追捕死亡天使》繁體中文化

這是給 ScummVM 使用的台灣繁體中文化工作樹，目標是將 Sierra 的
`Police Quest: In Pursuit of the Death Angel` 轉為 Big5 執行期文字。

## 版本

本專案把兩個版本完全分開處理：

- 原版 Floppy DOS：AGI 2.0G，target `agi:pq1`。
- VGA Remake：SCI/DOS，target `sci:pq1sci`。

兩者不是同一套資源，請勿混用 `original/agi` 與 `original/vga`。

## 安裝（玩家）

交付包只含中文化資料與打了中文 patch 的 ScummVM 執行檔，**不含遊戲本身**，
請自行準備合法取得的原始遊戲資料。

| 平台 | 檔案 | 內容 |
|---|---|---|
| Linux x86_64 | `pq1-cht-linux-x86_64.tar.gz` | 兩個 binary + 中文資料 |
| Windows x86_64 | `pq1-cht-windows-x86_64.zip` | 兩個 exe + SDL2.dll + 中文資料 |
| macOS universal | `pq1-cht-macos-universal.tar.gz` | arm64 + x86_64 雙弧 binary + 中文資料 |

解開後依包內的 `安裝說明.txt` 操作，重點是兩版的啟動方式不同：

```sh
# 原版 Floppy DOS（AGI）：不要加 --language
bin/scummvm-pq1-agi --extrapath=<本包>/game/agi --path=<你的遊戲資料夾>

# VGA Remake（SCI）：要加 --language=tw
bin/scummvm-pq1-sci --extrapath=<本包>/game/sci --language=tw --path=<你的遊戲資料夾>
```

AGI 版是以「`game/agi` 裡有沒有 `pq1_big5.fnt`」決定要不要開中文，不吃 `--language`；
它在 ScummVM 走 fallback 偵測，target 語言設成非英文反而無法啟動。SCI 版則相反。

包內附 `SHA256SUMS`，在包目錄下執行 `sha256sum -c SHA256SUMS`（macOS 用
`shasum -a 256 -c SHA256SUMS`）可驗證檔案完整性。

## 安裝（開發版）

1. 準備合法取得的原始遊戲資料；本專案不提供 `VOL.*`、`RESOURCE.*`、DOS 執行檔或 ROM。
2. 將原版資料放入 `workplace/original/agi/`，VGA 資料放入 `workplace/original/vga/`。
3. 使用 Docker 建置翻譯資料：

   ```sh
   docker compose -f workplace/docker/compose.yml run --rm pq1-tools sh tools/build_targets.sh
   ```

4. 使用對應的 `workplace/build/scummvm-pq1-agi` 或
   `workplace/build/scummvm-pq1-sci` 啟動遊戲。SCI target 的設定檔範例在
   `workplace/config/pq1sci.ini`，資料檔透過 `--extrapath=workplace/game/sci` 載入。

   Docker 內的乾淨 SCI target 可用專案腳本呼叫 ScummVM detector，避免手寫設定漏掉
   `path`：

   ```sh
   docker compose -f workplace/docker/compose.yml run --rm pq1-tools \
     sh tools/run_sci_normal_route.sh
   ```

## 中文化範圍與現況

AGI 與 SCI 都已完成資源偵測、文字骨架、OBJECT 道具名稱、Big5／hi-res 字型與
引擎 loader。最近一次產物統計為 AGI 2,816／3,177、SCI 3,566／3,667 筆翻譯，
placeholder 與 Big5 validator 皆 0 errors；實機 loader 記錄為
`AGI-CHT: 載入 2816 則翻譯` 與 `CHT: loaded 3566 translation entries`。

剩下未翻的鍵已逐項分類：AGI 361 筆中有 207 筆是抽字工具誤抽的引擎 opcode 與
parser 詞彙（`new.room`、`draw.pic`、`taxi` 之類，不會顯示給玩家），其餘是人名、
地址、車牌與 VIN 這類刻意保留英文的內容；SCI 101 筆同理。可翻的遊戲文字已翻完。

正常流程驗收仍在進行中，尚不能把目前產物視為完整發布版。NPC 對話、案件資料、
失敗結局與 credits 仍需逐項截圖驗收；目前已有 AGI 狀態列與訊息框、SCI 主選單與
開場旁白的中文畫面。

Docker Xvfb 已驗證兩版標題中文疊圖：`workplace/captures/pq1-agi-cht-start.png`
與 `workplace/captures/pq1-sci-overlay-start.png`。

SCI 的完整 intro 會進入中文主選單；`pq1-sci-real-menu.png` 為 Docker 實際畫面，
`pq1-sci-real-crawl.png`、`pq1-sci-after-crawl-pages.png`、
`pq1-sci-locker-room.png` 與 `pq1-sci-locker-interact.png` 是正常新遊戲流程的
開場旁白、警局走廊、更衣室與置物櫃互動畫面。

## 故事導讀

本作主角是利頓警察局警員 Sonny Bonds，玩家要依照警察勤務流程處理案件，
而不是只靠任意點擊推進。關水龍頭、穿制服、檢查武器、攜帶無線電、交通攔查與
無線電通報等細節，都可能影響遊戲結果。

關於本作寫實勤務與遊玩觀點，可參考貝卡的文章：

[貝卡的帕德嫩神殿：當警察從來就不是《金牌警校軍》——我玩《警察故事1》(Police Quest I) (1987)](https://bekanis.blogspot.com/2018/02/1-police-quest-i-1987.html)

文章是背景導讀與玩家觀點來源；版本、資源格式與技術行為仍以本專案的遊戲檔、
ScummVM log 與 Docker 驗收為準。

## 中文說明書前言

Sonny Bonds 的第一天勤務不是電影式的追車，而是一套必須逐項遵守的警察 SOP。
先讀勤務簡報，再穿制服、取回無線電與車鑰匙；出車前繞車檢查，執勤時依程序攔查、
宣讀權利、搜身、保管證物並回報調度。這些看似瑣碎的動作正是遊戲規則，漏掉任何一步
都可能扣分、停職或導向失敗結局。

## 快速攻略（不含防拷答案）

- 開場先完成簡報，進更衣室開啟自己的置物櫃；公報中的 Grunters 對 Sows 最終比分
  是置物櫃密碼 `269`。取制服、歸還無線電延伸器，再依勤務要求完成裝備。
- 交通勤務中先做完整安全檢查，攜帶警棍、關好車門，攔查時查看駕照、開單並取得簽名。
- 毒品案件中先聽 Laura 的埋伏指示，保持掩護；逮捕後先上手銬、搜身，再宣讀米蘭達權利，
  並把毒品、車輛與其他物品當正式證物處理。
- 不要把原始資源或防拷資料放入 patch 包；玩家必須自行準備合法取得的遊戲資料。

## 驗收畫面索引

以下畫面均由 Docker/Xvfb 產生，英文對照與執行記錄位於 `workplace/captures/`、
`workplace/latest-agi-run.log` 與 `workplace/latest-sci-run.log`：

- 中文／英文標題、開場旁白與主選單：`pq1-agi-cht-start.png`、`pq1-sci-real-menu.png`、
  `pq1-sci-real-crawl.png`。
- AGI 狀態列與訊息框（Big5 字型高度修正後）：`pq1-agi-fontfix-01-after-enter1.png`、
  `pq1-agi-fontfix-02-look.png`。
- 正常新遊戲警局路線：`pq1-sci-right-hallway.png`、`pq1-sci-locker-room.png`。
- 置物櫃案件提示與密碼流程：`pq1-sci-locker-interact.png`、
  `pq1-sci-locker-after-code.png`、`pq1-sci-locker-stage-open.png`、`pq1-sci-towel2.png`。
- 目前仍在補做完整 Dooley／案件／結局逐場景 A/B 驗收；覆蓋率與驗收狀態以
  [工作清單](workplace/WORKLIST.md) 為準。

## Patch-only 邊界

公開交付只包含引擎 patch、工具、翻譯 TSV、字型、checksum、README 與驗證記錄。
`workplace/original/`、`workplace/game/`、編譯 binary 與截圖均為本機／建置產物，
不應提交原始遊戲資料。

工作進度與未完成驗收項目見 [workplace/WORKLIST.md](workplace/WORKLIST.md)。
