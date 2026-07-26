# PQ1 繁體中文化翻譯指令（所有翻譯 subagent 開場必讀）

翻譯《Police Quest: In Pursuit of the Death Angel》的遊戲文字。本專案已有約 2,300 筆
既有譯文，你這批要與既有風格完全一致，不要自創新風格。

## 產出格式（硬規則，違反會被合併腳本擋下）

- 輸入檔每行是一個**英文原文 key**（純文字，無 tab）。
- 輸出 TSV 每行 `英文原文<TAB>繁體中文`，**英文原文一字不改**（大小寫、標點、前後空白、
  換行控制碼 `\n` 全部照抄）。它是遊戲執行期的查表 key，改了就查不到。
- 輸入幾行就輸出幾行，順序相同，不得增刪、不得合併、不得跳過。
- 檔案 UTF-8 無 BOM，每行一筆，值本身不得含 tab 或真實換行。

## 控制碼與佔位符

- `%s` `%d` `%u` `%m18` `%v30` `%g5` `%s3` 這類佔位符：**數量與拼寫完全保留**，只調整位置
  讓中文通順。`%m18` 是遊戲會替換的字串片段，前後要留得下通順的中文。
- `\n` 是字面兩字元的換行控制碼，原文有幾個就留幾個，位置盡量對應原本的斷行意圖。
- 開頭或結尾的空白（選單 padding）原樣保留。
- 原文若是純數字、車牌、代號（如 `BSOTD1`、`83-Nora-10`、`187`）、單純英文人名地名，
  照抄不譯，或只補必要的中文量詞。

## 編碼限制

- 一律台灣繁體中文，**所有字必須能以 Big5 編碼**。避免罕用字、日文漢字、簡體字、
  emoji、全形英數。標點用全形「，。？！：；……——「」『』（）」。
- 破折號用「——」，刪節號用「……」。不要用「·」以外的間隔號。

## 譯名定案表（統一，不得自創）

**原則：人名、地名、店名、單位專名一律保留英文原文，不音譯。** 這是既有 2,300 筆譯文的
主流做法，也避免音譯漂移。只有下表列出的少數詞才用中文。

### 人物（保留英文，職稱用中文）

| 原文 | 譯法 |
|---|---|
| Sonny Bonds | `Sonny`／`Bonds`／`Sonny Bonds`（**不可**寫「桑尼」「邦茲」） |
| Sgt. Dooley | `Dooley 警佐`（**不可**寫「杜利」） |
| Lt. Morgan | `Morgan 中尉` |
| Detective Laura Watts | `Laura Watts 警探` |
| Detective Oscar Hamilton | `Oscar Hamilton 警探` |
| Jessie Bains | `Jessie Bains`；綽號 the Death Angel = `死亡天使`、Jessie the Jeweler = `珠寶商 Jessie` |
| Sweet Cheeks Marie | `Sweet Cheeks Marie`（綽號保留英文） |
| Jack Cobb | `Jack Cobb` |
| Steve Rocklin | `Steve Rocklin` |
| Keith Robinson | `Keith Robinson` |
| Woody Roberts | `Woody Roberts` |
| Victor Simms | `Victor Simms` |
| Donald D. Colby | `Donald D. Colby`／`Don Colby` |
| Jimmy Lee Banksten "Whitey" | `Jimmy Lee Banksten`、綽號 `『Whitey』` |
| Carol、Frank、Angland、Barnum、Kathy、Sherry、Jose Martinez、Hoffman | 一律保留英文 |

### 地點（保留英文）

`Lytton`（**不可**寫「利頓」「立頓」；`Lytton, CA` 譯 `加州 Lytton`）、`Lytton PD`＝
`Lytton 警局`、`Blue Room`、`Cotton Cove`、`Clearwater River`＝`Clearwater 河`、
`Carol's Caffeine Castle`＝`Carol 咖啡城堡`、`Wino Willey's`＝`Wino Willey 酒館`、
`Jefferson High`＝`Jefferson 高中`、`Lytton City Park`＝`Lytton 市立公園`、
`Hotel Delphoria`＝`Delphoria 飯店`。

### 警務術語（統一用中文）

| 原文 | 譯法 |
|---|---|
| Detective | 警探（**不可**用「偵探」） |
| Officer | 警員 |
| Sergeant / Sgt. | 警佐 |
| Lieutenant / Lt. | 中尉 |
| Dispatch | 調度 |
| radio / mike | 無線電／麥克風 |
| patrol | 巡邏 |
| traffic stop | 交通攔查 |
| citation / ticket | 罰單 |
| suspect | 嫌犯 |
| arrest | 逮捕 |
| evidence | 證物 |
| Miranda rights | 米蘭達權利 |
| pat down / frisk | 搜身 |
| handcuffs / cuffs | 手銬 |
| PR-24 | PR-24 警棍 |
| DUI | 酒駕 |
| warrant | 通緝令／搜索票（依上下文） |
| booking | 建檔收押 |
| narcotics | 緝毒組（單位）／毒品（物品） |
| homicide | 命案／兇殺組 |
| 187 | 187（加州刑法兇殺代碼，照抄） |
| squad car / patrol car | 巡邏車 |
| locker | 置物櫃 |
| holster | 槍套 |
| informant | 線人 |
| State's evidence | 污點證人 |

## 語氣與風格

- 玩家視角敘述用第二人稱「你」，語氣中性、簡潔，像遊戲旁白。
- NPC 對白用引號「」，保留原文的口語、粗俗或俏皮語感，但不加原文沒有的網路流行語。
- 遊戲會嘲諷玩家的錯誤操作（例如亂撿垃圾、亂摸東西），保留那份揶揄語氣，別翻得太正經。
- 警察程序描述要準確；這款遊戲的賣點就是寫實勤務流程，術語不可含糊。
- 長度控制在原文的 ±30%，訊息框寬度有限，別暴增。
- 功能性短句（`Get closer.`、`Wanted for:`）就簡潔直譯，不要加戲。

## 收尾

只輸出 TSV 檔，不 commit、不改其他檔案。完成後回報：輸出路徑、行數、以及你不確定
或刻意保留英文的條目（≤5 條）。
