# M0 版本盤點

## 資料來源

| target | archive | 資源特徵 | 初步引擎 |
|---|---|---|---|
| `agi` | `Police Quest 1 - In Pursuit of the Death Angel (Floppy DOS).zip` | `LOGDIR`、`OBJECT`、`PICDIR`、`VIEWDIR`、`VOL.0..2`、`WORDS.TOK` | AGI |
| `vga` | `Police Quest 1 - In Pursuit of the Death Angel (Floppy DOS VGA Remake).zip` | `RESOURCE.000`、`RESOURCE.002..006`、`RESOURCE.MSG`、`MESSAGE.MAP`、`INTERP.*` | SCI |

## Archive 內容統計

- AGI：10 files，710,446 bytes（未壓縮內容）。
- VGA Remake：53 files，15,151,727 bytes（未壓縮內容）。
- 完整 SHA-256 見 `checksums.sha256`。

## 驗證狀態

Docker detector（ScummVM 2026.2.1git，2026-07-25 build）結果：

```text
agi:pq1     Police Quest: In Pursuit of the Death Angel (2.0G 1987-12-03/DOS/English)
sci:pq1sci  Police Quest: In Pursuit of the Death Angel (SCI/DOS/English)
```

原版使用 AGI-only binary（source baseline `cb8802d6e9d8`）；VGA 使用 SCI-enabled binary（source baseline `44ec20238f1c`）。AGI-only binary SHA-256：`2be9c9e31b0f801afac810787099c4bd52f0b21ea01b7f7050d1e78ebe8cc71d`。兩個 detector 都在 `pq1-cht-tools` Docker container 內執行。

資源檔案數量：AGI 10 files（710,446 bytes），VGA 53 files（15,151,727 bytes）。正式 SCI message/text/script 資源數量待 dump hook 完成後補記；本文件不把檔名猜測當作文字抽取完成證據。
