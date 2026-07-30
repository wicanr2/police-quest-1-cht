# 警察故事 1《追捕死亡天使》中文化

本文件以 `../police_quest2/CLAUDE-PQ2.md`（模板 v6）為基底，承襲其中的 SCI/AGI 中文化、Big5 字型、headless 驗收、三平台打包、README 與推廣素材規範，並補上 Police Quest 1 的版本差異。

## 0. 目標與邊界

- 遊戲：`Police Quest: In Pursuit of the Death Angel`，中文名暫定 **《警察故事 1：追捕死亡天使》**。
- 工作目錄：`@./workplace`（`/home/anr2/scummvm/police_quest1/workplace`）。
- 目標是可重建、可驗收、可公開分發的繁體中文 ScummVM patch。
- 公開 repository 只放引擎 patch、工具、翻譯資料、字型、README、攻略與推廣素材。
- **不得**提交原始 `RESOURCE.*`、`VOL.*`、`.DRV`、DOS executable 或 MT-32 ROM。
- 防拷答案原本也在禁列，2026-07-30 依使用者決定放行 **VGA 版條號表**一項：它是查手冊型
  防拷、綁在主要玩法裡，沒有條號玩不完，且條號是說明書上的參考資料而非遊戲程式碼或美術。
  中譯版放 `docs/中文條號速查.md` 並隨包附上。**這是單點例外**，其餘防拷／破解素材照舊不收。
- 玩家自行準備合法取得的原始遊戲資料；README 必須清楚說明 patch/full 差異。

# github repo（只放 patch-only）
 - https://github.com/wicanr2/police-quest-1-cht.git

## 1. PQ1 版本盤點（開工第一優先）

目前資料：

```text
../police_quest1/Police Quest 1 - In Pursuit of the Death Angel (Floppy DOS).zip
../police_quest1/Police Quest 1 - In Pursuit of the Death Angel (Floppy DOS VGA Remake).zip
```

兩個版本必須分開處理：

| 版本 | 資料特徵 | 起手確認 |
|---|---|---|
| 原版 Floppy DOS | `LOGDIR`、`OBJECT`、`PICDIR`、`VIEWDIR`、`VOL.*`、`WORDS.TOK` | detector、AGI 版本、LOGIC/VIEW/PIC 數量 |
| VGA Remake | `RESOURCE.000`、`RESOURCE.002`…、`MESSAGE.MAP`、`INTERP.*`、`MT32.DRV` | detector、SCI 版本、message/script/view/pic 數量 |

**不可只看檔名猜引擎。** 先用 ScummVM detector、資源 dump 與實機 log 確認。
如果兩版都做，建立不同的 target、翻譯表、checkpoint、`game/` 與 build 目錄，不能混資源。

### M0 盤點清單

1. 記錄兩份 archive 的 SHA-256，解壓到 gitignored 的 `original/agi/`、`original/vga/`。
2. 對兩版各跑 detector，記錄 engine、game id、版本、語言與資源數量。
3. 原版 dump LOGIC/OBJECT/VIEW/PIC/WORDS；VGA dump `text/message/script/view/pic`。
4. 先找 PQ1 VGA remake 或其他平台的同劇情譯本；正規化 key 後複用命中內容，不要先拿 PQ2 字串套用。
5. 確認兩版的故事文字、角色、地名、警察術語與防拷問題是否不同，建立版本專用 glossary。

## 2. 從 PQ2 承襲的硬規範

- 英文原文是 key、Big5 中文是 value；查無 key 時保留英文，不做模糊 substring 全域替換。
- 主線對白翻完不代表完成：選單、道具欄、system UI、狀態列、案件資料、失敗結局、credits、動態句與 script 內嵌字串都要抽查。
- AGI 的中文啟用靠字型與 `chtEnabled`；SCI 文字啟用靠 `language=tw`/`ZH_TWN`，兩者不可混用。
- SCI 必須另抽 script 內 Print 字串；`extract_strings.py` 只抽 message/text 不足以驗收。
- `kFormat` 的 `%s/%d` 模板要在格式化前翻譯；插入的 `%s` 也要在模板已翻譯時查表，格式不安全就退回英文。
- key 與查詢字串的空白、CR/LF、tab 要雙邊正規化；選單 padding 空格不可無意刪除。
- 含硬換行的 crawl/過場 script 字串先整理成單行 key，避免逐行 TSV parser 把整段丟掉。
- Big5 字型以所有譯文 value 建構，標點與引擎硬寫字串也必須有 glyph；ETEN 點陣字優先於縮小 TTF。
- 斷行以顯示欄位計算，不能按 Big5 byte；檢查日文 SJIS kinsoku 是否誤傷 Big5。
- 引擎硬寫 Big5 C++ 字串要讓 clang 安全：反斜線十六進位 escape 後若接 hex 字元，要用相鄰字串打斷。
- 每項驗收都要讀實際截圖；中文與英文同場景 A/B 對照，不能只看測試綠燈或覆蓋率。
- Docker 使用專案專用 container name，只清理自己建立的 container；長時間 headless 指令一定有 timeout，不可無限 `wait` 背景 Xvfb。

## 3. 原版 AGI 路線

若 detector 確認 Floppy DOS 是 AGI：

- 使用 `agi` engine；不要使用 `--language=tw`，避免 AGI fallback 因非英文語言無法啟動。
- 以 Big5 字型存在與 `_chtEnabled` 作為 gate；中文開啟後確認 forceHires 640×400、16×16 字格與訊息框位置。
- 抽 LOGIC 訊息、OBJECT 道具名與 system UI 硬寫字串；OBJECT 若以 `Avis Durgan` XOR 解密，先解密再建表。
- 驗證 `displayText`、道具欄、暫停、存讀檔、Score/Sound 狀態列，不可只看對話框。
- `loadChtResources()` 必須早於 `new SystemUI`，避免 SystemUI 建構時抓不到中文資源。
- AGI 判斷用 `chtEnabled()`；若做 F8 中英切換，另設 `_chtLangOn`，不要重用 `_chtEnabled`。

## 4. VGA Remake SCI 路線

若 detector 確認 VGA Remake 是 SCI：

- 確認確切 SCI 版本與畫布，不可直接假設一定是 SCI1.1 或可照抄 PQ2 hook。
- `SCI_DUMP_RES` 要包含 message/text/script/view/pic；實機再以 `SCI_LOG_GFX=1` 定位畫面。
- 先用英文跑通開場、警局、交通攔查、案件資料與失敗結局，再開始改引擎。
- pic 是向量指令流，不能當點陣直接重繪；view cel 才考慮 decode/encode。
- hi-res live text 的 `getDisplayWidth()`、advance、glyph、row stride、wrap 必須同一套條件。
- 防拷 bypass 只能依 PQ1 實際 call path 實作；不可無條件套入 PQ2/LSL2 的 patch。
- 所有 engine hook 以 PQ1 VGA 實際 log、源碼與 A/B 畫面為準，不能只複製檔名或行號。

## 5. 翻譯批次與台式在地化

- 建立 `translation/full_skeleton.tsv`、數字排序的 `translation/batch/`、`translation/glossary.tsv`。
- 批次按範圍拆分：開場、警局 UI、交通攔查、案件檔案、嫌犯、武器/證物、結局、system UI。
- 先固定警察術語：警徽、巡邏、攔查、盤問、逮捕、證物、通緝、調度、嫌犯、警局與報案。
- 保留 `%s/%d/%u`、換行控制碼、padding 空格與控制符號；做 placeholder/schema validator。
- 翻譯使用台灣繁體中文；人名、地名、LPD 等專名先定案，不混入簡體或中國用語。
- 每批完成後做 TSV、duplicate key、placeholder、Big5 可編碼與字型 coverage 檢查。
- 覆蓋率只是指標；script、crawl、動態句與 UI 漏譯必須靠實機流程抓出來。

## 6. 驗收里程碑

| 里程碑 | 證據 |
|---|---|
| M0 版本辨識 | archive checksum、detector/log、資源清單 |
| M1 抽字 | AGI/SCI 各自 skeleton、抽取工具、候選統計 |
| M2 繪字 | 中文標題/選單/訊息框 screenshot，英文回歸畫面 |
| M3 翻譯 | batch validator、覆蓋統計、未翻鍵分類 |
| M4 完整性 | 道具、案件、動態句、script、crawl、失敗結局、credits |
| M5 正常流程 | 不跳過 intro，實際走到 NPC 對話、案件查閱、證物操作、失敗或結局 |
| M6 交付 | Windows/Linux patch+full、macOS universal app/dmg、README/攻略 |
| M7 推廣 | 中文手冊前言、實機截圖、可重建 promo video |

**M5 是硬門檻。** 選單或開場中文不代表完成；至少要留下真正 NPC 對話與英文同場景對照證據。

## 7. 打包與 GitHub Actions

- 每平台做兩軌：patch 只含引擎與中文資料；full 的原始遊戲資源只在本機組裝，公開 repo 不放資源。
- macOS 用 `macos-14` 或當時可用的 Apple Silicon runner；arm64 原生、x86_64 走 Rosetta，兩弧分開 checkout/build，再 `lipo -create`。
- SDL2 使用 pinned source build，避免 sdl2-compat/SDL3 shim 黑畫面；產物用 `file`/`lipo -info` 驗 universal。
- macOS 注入來源使用版控 `dist-cht/`，不能依賴 gitignored `game/`；清單要含全部 tsv、字型與 title overlay。
- push 後觸發 workflow 前先 `git ls-remote origin main`；觸發後用 `gh run view <id> --json headSha` 核對 commit。
- CI job 綠燈後仍要下載 artifact，檢查 app binary 架構、中文資料路徑、tar listing、dmg 存在性與資料 checksum。
- 空 repo 的 workflow_dispatch 若 404，先推到預設分支觸發 workflow 掃描；必要時用符合 workflow 的 tag 觸發。

## 8. README、手冊與推廣片

README 必須是面向玩家的繁中介紹，包含 PQ1 劇情、Sonny Bonds、死亡天使案件、原版與 VGA Remake 差異、中文說明書前言、足夠中文遊戲畫面、安裝方式、patch/full 邊界、攻略、驗收證據與 GitHub 連結。

### 必須引用的遊戲評論

README 的遊戲介紹與中文攻略必須引用這篇繁中文章：

> [貝卡的帕德嫩神殿：當警察從來就不是《金牌警校軍》——我玩《警察故事1》 (Police Quest I) (1987)](https://bekanis.blogspot.com/2018/02/1-police-quest-i-1987.html)

引用時要以文章作為背景與玩家觀點來源，不要整段抄錄。應整理並標註以下重點：

- Sierra 從《國王密使》《宇宙傳奇》的奇幻/科幻冒險，延伸到以當代現實為背景的《警察故事》。
- 本作刻意強調寫實勤務：關水龍頭、穿衣進浴室、歸還無線電與巡邏車鑰匙等細節都可能影響分數或結果。
- 遊戲核心不是任意探索，而是依照警察勤務流程辦案；說明書中的開罰單、逮捕、無線電通報等 SOP 是遊戲規則的一部分。
- 開車前安全檢查、攜帶警棍、妥善保管配槍、離車關門等疏忽會造成具體失敗，這正是 PQ1 與一般警匪電影式冒險的差異。
- 文章可作為 README「為什麼 PQ1 值得中文化」與攻略「先讀手冊、照章辦事」兩節的導讀，但遊戲數值、版本、資源格式仍以實機與 ScummVM reference 驗證為準。

不要把該文章當成原始遊戲手冊或唯一史料；涉及發行年份、版本、資源、版權與技術行為時，必須另以遊戲檔、說明書、ScummVM detector/log 與實機畫面交叉確認。

推廣片沿用 PQ2 實戰規格：約 40–60 秒，使用實機 headless 截圖，涵蓋標題、baked-art、live NPC 對白、AGI/SCI 版本亮點與片尾 repo URL。若有合法原版音樂，優先 MT-32 即時 SDL disk-audio；全速 `SDL_DISKAUDIODELAY=0` 會讓 SCI 排序器近乎靜音，不可誤判音訊 pipeline 壞掉。素材放 gitignored `out/video_src/`，重建腳本放 `tools/`，成品放 `docs/promo/`。

## 9. 必讀 knowledge-base / rulebook

開工必讀：

1. `~/.claude/knowledge-base/retro-cht/retro-avg-taiwanese-localization/SKILL.md`
2. `~/.claude/knowledge-base/retro-cht/scummvm-sci-cht-localization`（VGA 確認為 SCI 後）
3. `~/.claude/knowledge-base/retro-cht/eten-bitmap-font`
4. `~/.claude/knowledge-base/retro-cht/game-promo-video-ffmpeg`（做影片時）

PQ1 對外介紹必須引用：

5. [貝卡的帕德嫩神殿：當警察從來就不是《金牌警校軍》——我玩《警察故事1》 (Police Quest I) (1987)](https://bekanis.blogspot.com/2018/02/1-police-quest-i-1987.html)

需要時讀：`workflows/batch-subagent-localization.md`、`rulebook/60-feedback-loop-priority.md`、
`64-re-screenshot-oracle.md`、`65-verify-against-reference-not-internal-signals.md`、
`80-retro-cht-readme-polish.md`、`81-retro-cjk-hires-canvas.md`、
`83-retro-completeness-over-roi.md`、`93-promo-video-original-assets.md`。

## 10. 交付前 checklist

- [ ] AGI 原版與 VGA Remake 已分開辨識、分開測試，沒有混資源。
- [ ] archive checksum、detector 結果與 pinned ScummVM commit 已記錄。
- [ ] 主線、UI、道具、案件、script、動態句、crawl、失敗結局與 credits 已抽查。
- [ ] Big5 字型包含標點與所有譯文 glyph；字型 oracle 可辨識。
- [ ] 中文/英文同場景 A/B 截圖完成；正常流程走到 NPC 對話。
- [ ] parser、placeholder、TSV、duplicate、未翻鍵 validator 通過。
- [ ] patch/full 沒有原始資源、ROM 或 DOS executable。
- [ ] macOS universal artifact 經 `file`/`lipo`、tar listing 與 checksum 驗證。
- [ ] README 有中文手冊前言、遊戲介紹、畫面、攻略與推廣影片。
- [ ] HANDOFF.md、CONTEXT.md、WORKLIST.md 只記錄 code/畫面證據支持的完成狀態。

完成宣稱必須列出版本、翻譯數、實機截圖、英文回歸、三平台 artifact、Git commit 與已知限制；不可只寫覆蓋率。
