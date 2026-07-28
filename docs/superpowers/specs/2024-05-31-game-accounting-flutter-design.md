# Design Doc: Game Accounting Pro (Windows & Android)

## 1. Overview
A standalone, cross-platform accounting application for Windows and Android to replace the legacy Streamlit-based "Personal Game Ledger." The app focuses on reducing data entry complexity, providing high-performance local storage, and separating "Game Purchases" from "In-game Services."

## 2. Goals & Success Criteria
- **Standalone:** No Python server required; runs as a native `.exe` (Windows) and `.apk` (Android).
- **Reduced Complexity:** Move from hierarchical dropdowns to a smart "Search-First" entry system.
- **Data Integrity:** Transition from CSV to SQLite for relational data management.
- **Visual Clarity:** Separate one-time game purchases from recurring service costs.
- **Extensibility:** Support custom icons/images and future modular features.

## 3. Architecture & Tech Stack
- **Framework:** Flutter (3.x)
- **Programming Language:** Dart
- **Database:** SQLite (via `drift` package)
- **State Management:** Provider or Riverpod (for clear separation of UI and Logic)
- **Local Storage:** `path_provider` for default paths and `file_picker` for custom data locations.

## 4. Data Model (SQLite)
- **Table: Publishers**
  - id (int, PK)
  - name (text, unique)
  - icon_path (text, optional)
- **Table: Games**
  - id (int, PK)
  - publisher_id (int, FK)
  - name (text)
  - category (enum: 'Library', 'Service', 'Hardware')
  - icon_path (text, optional)
- **Table: Entries**
  - id (int, PK)
  - game_id (int, FK)
  - date (datetime)
  - item_name (text)
  - price (real)
  - quantity (int)
  - note (text, optional)

## 5. Key Features

### 5.1 Smart Entry System
- **Omni-Search:** A single text field that suggests existing Games/Publishers as you type.
- **Auto-Fill:** Selecting a game automatically sets the Publisher and Category (Library vs Service).
- **Quick Action Buttons:** Grid of "Top 5" frequent purchases for one-tap entry.

### 5.2 Legacy Migration
- **CSV Importer:** A tool that reads the existing `game_expenses.csv` and maps columns to the new SQLite schema.

### 5.3 Data Management
- **Portable DB:** Users can manually set the database file location in Settings.
- **Media Support:** Local folder storage for custom game/publisher icons.

### 5.4 Specialized Analytics
- **The "Chaos Fix":** Dashboard separates total spending into "Library Value" (Buy-to-play) and "Burn Rate" (Microtransactions/Subscriptions).
- **Filtering:** Instant toggle between platform views (e.g., "PC/Steam only" vs "Mobile only").

## 6. Implementation Phases
1. **Core:** Flutter project setup + SQLite schema definition.
2. **Data Utility:** CSV migration tool development.
3. **UI - Entry:** Smart Search and Entry form implementation.
4. **UI - Dashboard:** Charting and specialized "Library vs Service" views.
5. **Assets:** Icon/Image selection and management.
6. **Packaging:** Build `.exe` and `.apk` installers.
