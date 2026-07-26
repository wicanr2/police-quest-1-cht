# PQ1 繁中化交接記錄

## 目前狀態

- AGI Floppy DOS：2,816／3,177 筆翻譯。
- SCI VGA Remake：3,566／3,667 筆翻譯。
- 兩版 placeholder／Big5 validator 均 0 errors；未翻鍵的分類與理由見 `WORKLIST.md`，
  全數是引擎符號或刻意保留的專名／代號，可翻的遊戲文字已翻完。
- Linux 與 Windows 交付包已在本機建好並實跑驗證；macOS universal 走 CI。

## 建置方式

Linux 與 Windows 都在本機 Docker 建完，不佔 CI；只有 macOS 非借 runner 不可
（Apple SDK 不能在 Linux 上交叉編譯）。

```sh
# Linux（預設用 .build-{agi,sci}-src 增量 make；--clean 則從 pinned upstream 重建）
docker compose -f docker/compose.yml run --rm pq1-tools sh tools/build_linux_release.sh

# Windows（mingw-w64 交叉編譯，SDL2 用 libsdl-org 官方 mingw devel 包）
docker compose -f docker/compose.yml run --rm pq1-mingw sh tools/build_windows_release.sh

# macOS universal
gh workflow run build-cht-packages.yml
```

## 本輪修掉的缺陷

1. **AGI 狀態列只顯示得出「得」**：`loadPrefixedRaw(fontFile, 16)` 與 `build_cht.py --size 15`
   產出的 15 列字型不符。`loadPrefixedRaw` 按 `2 + height*2` bytes 逐筆讀，高度對不上就
   逐筆錯位，只有偶然對齊的字查得到 glyph。SCI 端一直是 15，只有 AGI 中招。
2. **AGI 中英混雜**：`stringPrintf` 展開 `%m`／`%g` 子訊息時直接取原始英文，外層
   `displayText` 只對拼接完成的整串查表，那串不是表裡的 key。改成展開前先各自查表。
3. **字型缺引擎硬寫 UI 字**：字集只從譯文 value 收集，漏掉只出現在引擎硬寫字串裡的字
   （如「擇」）。加 `ENGINE_UI_CHARS` 補烘。
4. **SCI 訊息框裁切句尾**：`GfxText16::Size()` 量英文、`Box()` 畫中文，框開得太小。
   在 `Size()` 加上同樣的查表。**此項尚未取得畫面證據**，見下。
5. **`patches/fontchinese.cpp` 與實際編譯版本不一致**：版控是 `kBig5Width=12`／`kHiW=24`，
   實際編的是 16／32。現行 hi-res 字型是 32×28，用版控那份重建會讀錯格式。
6. **SHA256SUMS 記絕對路徑**：玩家解包後照說明校驗會全數 not found。改記相對路徑，
   並改用可攜寫法（macOS 沒有 GNU `sha256sum`，只有 `shasum`）。

兩個 engine patch 已改為從「乾淨 pinned upstream vs 實際編譯樹」重新產生，並驗證
`patch -p1 --dry-run` 乾淨套用、套用後每個檔案與 `.build-*-src` 逐檔完全一致。
版控的 patch 與已驗證過的 binary 是同一份東西。

## 下一位接手要注意的事

- **SCI 裁切修正缺畫面證據**。headless 容器的滑鼠事件送不進 SCI，跳不過開場動畫
  （試過 `run --rm` 短容器、長駐容器、debugger `room` 跳轉、長時間等待自然播完，
  都不行；`room 269` 在這版是 `Script 269 not found`）。需要能操作真實滑鼠的環境重跑，
  對照 `captures/pq1-sci-m4-99-wall-msg-truncated.png`。
- macOS CI 踩過三個雷，都已修但值得記著：configure 用 uname 判 host CPU（x86_64 弧要
  整個跑在 `arch -x86_64` 下否則 NEON 編不過）、Homebrew 只有 arm64 版 codec（要
  `--disable-*` 全關）、macOS 沒有 `sha256sum`。
- 其餘未走到的場景與已知限制列在 `WORKLIST.md`，不必重查。
