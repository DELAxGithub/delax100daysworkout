# VS Code ビルドガイド

## 概要
このガイドは、VS Code から Xcode プロジェクトをビルドするための手順を説明します。

## 前提条件
- Xcode がインストールされていること
- Xcode のコマンドラインツールがインストールされていること

## ファイル構造
すべての Swift ファイルは以下の構造に配置されています：

```
Delax100DaysWorkout/
└── Delax100DaysWorkout/
    ├── Application/
    │   └── MainView.swift
    ├── Features/
    │   ├── ContentView.swift
    │   ├── DashboardView.swift
    │   ├── DashboardViewModel.swift
    │   ├── LogEntryView.swift
    │   ├── LogEntryViewModel.swift
    │   ├── ProgressChartView.swift
    │   ├── ProgressChartViewModel.swift
    │   ├── SettingsView.swift
    │   ├── SettingsViewModel.swift
    │   ├── WorkoutCardView.swift
    │   └── ProgressCircleView.swift
    ├── Models/
    │   ├── UserProfile.swift
    │   ├── DailyLog.swift
    │   └── WorkoutRecord.swift
    └── Delax100DaysWorkoutApp.swift
```

## ビルド手順

### 1. コマンドラインからビルド
プロジェクトルートで以下のコマンドを実行：

```bash
./build.sh
```

### 2. 手動でビルド
```bash
cd Delax100DaysWorkout
xcodebuild build \
    -project Delax100DaysWorkout.xcodeproj \
    -scheme Delax100DaysWorkout \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest'
```

### 3. シミュレーターで実行
```bash
cd Delax100DaysWorkout
xcodebuild build-for-testing \
    -project Delax100DaysWorkout.xcodeproj \
    -scheme Delax100DaysWorkout \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest'

# シミュレーターを開く
open -a Simulator

# アプリを実行
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/Delax100DaysWorkout.app
xcrun simctl launch booted com.yourcompany.Delax100DaysWorkout
```

## トラブルシューティング

### "Cannot find 'MainView' in scope" エラーが発生する場合

1. Xcode を開く
2. 各 Swift ファイルを選択
3. File Inspector で "Target Membership" にチェックを入れる
4. すべてのカスタムファイルで手順 2-3 を繰り返す

詳細は `xcodehandout.md` を参照してください。

### シミュレーターが見つからない場合

利用可能なシミュレーターを確認：
```bash
xcrun simctl list devices
```

## VS Code 推奨拡張機能

- **Swift** - Swift 言語サポート
- **SwiftLint** - コード品質チェック

## 注意事項

- 新しい Swift ファイルを追加した場合は、必ず Xcode でターゲットメンバーシップを設定してください
- ビルドエラーが発生した場合は、`error/` フォルダ内のログファイルを確認してください