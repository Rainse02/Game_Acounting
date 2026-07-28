# 游戏账本 (Game Ledger)

一个简洁的跨平台（Android & Windows）游戏消费记账应用。
A simple cross-platform (Android & Windows) game spending tracker.

[中文](#中文) | [English](#english)

---

## 中文

### 功能

- **智能记账** — 游戏/厂商搜索联想，自动带出分类；支持随时**编辑**已有记录（v2 新增）
- **明细管理** — 按月分组显示小计，支持关键词搜索、分类筛选、日期范围筛选，左滑删除可撤销（v2 新增）
- **消费看板** — 分类占比环形图、月度/年度趋势柱状图（跨年数据不再混算，v2 修复），点击图表下钻明细
- **月度预算** — 设置每月预算，看板实时显示进度与超支提醒（v2 新增）
- **数据管理**
  - CSV 导出/导入：**导入前预览**、自动识别新旧三种格式、重复记录检测（v2 重做）
  - JSON 完整备份/恢复：无损保留厂商、游戏、记录与设置的完整关系（v2 新增）
- **中英双语** — 跟随系统语言自动切换（v2 新增）

### 开始开发

环境要求：Flutter SDK（stable 渠道）、Dart 3.x。

```bash
git clone https://github.com/Rainse02/Game_Acounting.git
cd Game_Acounting

# 一键初始化：拉取依赖 + 生成 drift 数据库代码 + 生成本地化代码
./tool/bootstrap.sh        # Windows: tool\bootstrap.bat

flutter run
```

> **注意**：`lib/data/database.g.dart` 与 `lib/l10n/app_localizations*.dart`
> 均为生成代码。修改 `database.dart` 表结构或 `.arb` 文案后需重新运行
> bootstrap（或 `dart run build_runner build` / `flutter gen-l10n`）。

### 构建发布版

```bash
# 按 CPU 架构拆分构建，单个 APK 体积可比通用包小 60% 以上
flutter build apk --release --split-per-abi

# 上架 Google Play 用 App Bundle（商店按设备自动下发对应架构）
flutter build appbundle --release
```

推送 `v*` 标签（如 `v2.0.0`）后，GitHub Actions 会自动完成
分析 → 测试 → 构建拆分 APK → 挂到 GitHub Release。

**正式签名**：复制 `android/key.properties.example` 为
`android/key.properties` 并填入自己的密钥库信息（勿提交到 git）。
未配置时回退为 debug 签名，便于本地验证。

### CSV 格式

导出表头（同时也是推荐的导入格式）：

```
日期,分类,厂商,游戏,项目,单价,数量,总额,备注
2025-03-01,Service,米哈游 (miHoYo),原神,月卡,30.0,1,30.0,
```

- `分类` 取值：`Library`（买断）/ `Service`（内购）/ `Hardware`（相关），
  中文写法（买断/内购/相关）亦可识别
- 导入按**表头名称**匹配列，因此旧版应用导出的 CSV 及
  legacy Python 版导出（`用户,日期,...`）都能正确导入，日期与分类不会丢失
- 文件带 UTF-8 BOM，Excel 直接打开不乱码

### 项目结构

```
lib/
├── main.dart                 # 入口 + 多语言配置
├── l10n/                     # 中英文案 (.arb)
├── data/
│   ├── database.dart         # drift 表定义 + 查询（schema v2）
│   ├── csv_service.dart      # CSV 导出/解析/查重/导入
│   └── backup_service.dart   # JSON 完整备份/恢复
└── ui/
    ├── home_page.dart        # 底部导航
    ├── dashboard_screen.dart # 看板：预算、图表、年份切换
    ├── entry_list_screen.dart# 明细：搜索/筛选/编辑入口
    ├── entry_edit_screen.dart# 新增/编辑记录
    ├── data_management_screen.dart
    └── import_preview_screen.dart # 导入预览与查重
```

---

## English

### Features

- **Quick entry** with game/publisher autocomplete and auto-categorization; entries are fully **editable** (new in v2)
- **History** grouped by month with subtotals, keyword search, category and date-range filters, swipe-to-delete with undo (new in v2)
- **Dashboard** with category donut, monthly/yearly trend bars (years are no longer merged — fixed in v2) and tap-to-drill-down
- **Monthly budget** with live progress and overspend warning (new in v2)
- **Data management**
  - CSV export/import with **import preview**, automatic format detection (three historical layouts) and duplicate detection (rebuilt in v2)
  - Lossless JSON full backup/restore incl. publishers, games and settings (new in v2)
- **English & Chinese UI**, following the system language (new in v2)

### Getting started

Requires the Flutter SDK (stable channel), Dart 3.x.

```bash
git clone https://github.com/Rainse02/Game_Acounting.git
cd Game_Acounting
./tool/bootstrap.sh        # Windows: tool\bootstrap.bat
flutter run
```

`lib/data/database.g.dart` and `lib/l10n/app_localizations*.dart` are
generated code — rerun the bootstrap script after changing the schema or the
`.arb` files.

### Release builds

```bash
flutter build apk --release --split-per-abi   # small per-ABI APKs
flutter build appbundle --release             # for Google Play
```

Pushing a `v*` tag triggers the GitHub Actions release workflow
(analyze → test → build → attach APKs to the GitHub Release).

For proper release signing, copy `android/key.properties.example` to
`android/key.properties` and fill in your keystore details (never commit it).

### License

MIT — see [LICENSE](LICENSE).
