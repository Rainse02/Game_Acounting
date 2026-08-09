# 🎮 GameA (游戏账本) v1.1.1

一个简洁、优雅且功能强大的跨平台（Android & Windows）游戏消费记账与数据分析应用。  
*A sleek, intuitive, and cross-platform game spending tracker and financial analytics app.*

[中文功能指南](#-中文指南) | [English Guide](#-english-guide)

---

## 🇨🇳 中文指南

### ✨ 核心亮点

- 🎮 **智能记账**
  - **联想补全**：内置常用厂商与游戏下拉搜索，自动带出分类（买断 / 内购 / 硬件）。
  - **灵活编辑**：支持随时对已记录的消费进行二次修改，记录准确无误。

- 📊 **多维看板与图表**
  - **消费分布**：直观的分类环形占比图，点击扇区可直接下钻查看明细。
  - **趋势分析**：月度与年度消费柱状图，支持年份自由切换与全历史总览。

- 💰 **月度预算管理**
  - 自定义设置每月消费预算，看板实时展示已用额度、剩余金额与进度条，超出时提供清晰预警。

- 🔍 **明细管理与搜索**
  - **分组小计**：按月份分组展示总支出与笔数。
  - **精准筛选**：支持关键字（游戏 / 项目 / 厂商）实时搜索、分类 Chip 快速过滤及自定义日期范围筛选。
  - **防误删保护**：列表左滑快速删除，提供底部撤销 (Undo) 按钮。

- 🛡️ **数据安全与无损备份**
  - **JSON 完整无损备份**：一键导出包含账目、厂商、游戏与预算设置的全量备份，换机无忧。
  - **智能 CSV 导出/导入**：导出表格带 UTF-8 BOM（Excel 打开无乱码）；导入带**预览与去重**功能，兼容各类历史数据。

- 🌐 **中英双语**
  - 原生支持中文与英文界面，跟随手机 / 电脑系统语言自动切换。

---

### 📲 下载与使用

- **Android 手机用户**：
  下载最新 release 版本 `app-arm64-v8a-release.apk`，在手机上安装即可直接使用。支持覆盖升级安装，历史账目数据绝对不会丢失。
- **Windows 桌面用户**：
  直接运行桌面客户端，享受大屏看板与便捷的快捷键体验。

---

### 📄 CSV 导入与导出格式规范

导出文件采用标准 UTF-8 BOM 编码，推荐格式如下：

```csv
日期,分类,厂商,游戏,项目,单价,数量,总额,备注
2026-03-01,Service,米哈游 (miHoYo),原神,月卡,30.0,1,30.0,
2026-03-05,Library,Steam,黑神话：悟空,游戏本体,268.0,1,268.0,标准版
```

- **分类取值说明**：
  - `Library`（买断制游戏 / 本体）
  - `Service`（内购 / 抽卡 / 订阅月卡）
  - `Hardware`（游戏外设 / 硬件设备）
- **兼容性**：导入器按表头名称智能匹配，完美兼容旧版 App 及 Python 导出表格。

---

## 🇬🇧 English Guide

### ✨ Key Features

- 🎮 **Smart Logging**
  - **Autocomplete**: Search publishers & games with automatic category detection (Buy-to-play / In-app / Peripherals).
  - **Full Editability**: Edit any existing transaction at any time.

- 📊 **Interactive Dashboard**
  - **Category Donut**: Visualize spending distribution by category; tap to view detailed entries.
  - **Trend Analysis**: Monthly and yearly bar charts with full multi-year filtering.

- 💰 **Monthly Budget Control**
  - Set a target monthly budget with live progress bars, remaining balance indicators, and overspend warnings.

- 🔍 **History & Filtering**
  - **Monthly Subtotals**: Entries grouped by month with item count and cost totals.
  - **Search & Filters**: Search by keyword, filter by category chip, or set custom date ranges.
  - **Swipe-to-Delete**: Quick swipe deletion with instantaneous SnackBar Undo.

- 🛡️ **Data Security & Lossless Backup**
  - **JSON Full Backup**: Lossless full export/restore including games, publishers, and budget settings.
  - **Smart CSV Import/Export**: Excel-friendly UTF-8 BOM exports; import preview with automatic duplicate detection.

- 🌐 **Multilingual Support**
  - Seamless English and Chinese UI, following your system language preference.

---

### 📄 Standard CSV Specification

```csv
Date,Category,Publisher,Game,Item,UnitPrice,Quantity,Total,Note
2026-03-01,Service,miHoYo,Genshin Impact,Monthly Pass,30.0,1,30.0,
```

- **Categories**: `Library` (Buy-to-play), `Service` (In-app / Subscriptions), `Hardware` (Peripherals & Gear).

---

### 📜 License

Distributed under the [MIT License](LICENSE).
