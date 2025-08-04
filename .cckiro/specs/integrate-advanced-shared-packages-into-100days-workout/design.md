# 設計ファイル: delax-shared-packages統合

## アーキテクチャ設計

### 1. システム全体構成

```
delax100daysworkout/
├── Package.swift (NEW: DelaxSwiftUIComponents依存追加)
├── Delax100DaysWorkout/
│   ├── Models/ (既存維持)
│   ├── Features/ (既存維持)
│   ├── Services/ (UPGRADE)
│   │   ├── BugReportManager.swift → DelaxBugReportManager統合
│   │   ├── GitHubService.swift → 共有パッケージ版利用
│   │   └── (その他既存サービス維持)
│   └── Application/ (既存維持)
├── auto-fix-config.yml (NEW: 自動修正設定)
└── .github/workflows/ (UPGRADE: Auto-Fix統合)
```

### 2. 依存関係設計

#### Package.swift設計
```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Delax100DaysWorkout",
    platforms: [.iOS(.v17)],
    dependencies: [
        .package(
            url: "https://github.com/DELAxGithub/delax-shared-packages.git",
            branch: "main"
        )
    ],
    targets: [
        .executableTarget(
            name: "Delax100DaysWorkout",
            dependencies: [
                .product(name: "DelaxSwiftUIComponents", 
                        package: "delax-shared-packages")
            ]
        )
    ]
)
```

### 3. バグレポート機能統合設計

#### 3.1 移行戦略
1. **段階的移行**: 既存機能を維持しながら新機能を追加
2. **設定統合**: EnvironmentConfigとDelaxBugReportManagerの設定を統合
3. **API互換性**: 既存のメソッド呼び出しを維持

#### 3.2 BugReportManager 統合設計
```swift
// 移行前 (現在)
import Foundation
class BugReportManager: ObservableObject {
    static let shared = BugReportManager()
    // ...既存実装
}

// 移行後
import DelaxSwiftUIComponents
typealias BugReportManager = DelaxBugReportManager

// Application起動時設定
DelaxBugReportManager.shared.configure(
    gitHubToken: EnvironmentConfig.githubToken,
    gitHubOwner: EnvironmentConfig.githubOwner,
    gitHubRepo: EnvironmentConfig.githubRepo
)
```

#### 3.3 ShakeDetector統合
```swift
// 既存のShakeDetectorを DelaxShakeDetector に置き換え
import DelaxSwiftUIComponents

// MainView.swift での利用法
.onReceive(DelaxShakeDetector.shared.shakePublisher) { _ in
    DelaxBugReportManager.shared.showBugReportView()
}
```

### 4. iOS Auto-Fix機能統合設計

#### 4.1 設定ファイル設計 (auto-fix-config.yml)
```yaml
project:
  name: "Delax100DaysWorkout"
  xcode_project: "Delax100DaysWorkout.xcodeproj"
  scheme: "Delax100DaysWorkout"
  
build:
  max_attempts: 5
  timeout_seconds: 300
  destination: 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest'
  
claude:
  model: "claude-4-sonnet-20250514"
  
watch:
  directories:
    - "Delax100DaysWorkout/Models"
    - "Delax100DaysWorkout/Features"
    - "Delax100DaysWorkout/Services"
  debounce_seconds: 3
  include_patterns: ["*.swift"]
  exclude_patterns: ["*.xcuserstate", "*.pbxproj"]

error_detection:
  ignore_patterns:
    - "warning:.*deprecated"
  critical_patterns:
    - "error:.*"
    - "fatal error:.*"
```

#### 4.2 GitHub Actions 統合
```yaml
name: iOS Auto Build & Fix
on:
  push:
    paths: [ 'Delax100DaysWorkout/**/*.swift' ]
  pull_request:
    paths: [ 'Delax100DaysWorkout/**/*.swift' ]

jobs:
  auto-build-fix:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - name: Setup iOS Auto-Fix
        run: |
          git clone https://github.com/DELAxGithub/delax-shared-packages.git /tmp/shared
          cp /tmp/shared/native-tools/ios-auto-fix/Scripts/* ./scripts/
          chmod +x ./scripts/*.sh
      - name: Run Auto-Fix
        run: ./scripts/auto-build-fix.sh
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

### 5. データフロー設計

#### 5.1 バグレポートフロー
```
[Shake Detection] → [DelaxShakeDetector]
                     ↓
[BugReport UI] → [DelaxBugReportView]
                     ↓
[Report Creation] → [DelaxBugReportManager.captureBugReport()]
                     ↓
[GitHub Issue] → [DelaxBugReportManager.submitBugReport()]
                     ↓
[Auto-Fix Trigger] → [GitHub Actions Workflow]
```

#### 5.2 Auto-Fix フロー
```
[File Change] → [Watch Mode] → [Build Attempt] → [Error Detection]
                                                      ↓
[Claude Analysis] → [Patch Generation] → [Safe Application] → [Verification]
                                                                    ↓
[Success] → [Commit] → [Notification]
    ↓
[Failure] → [Rollback] → [Manual Investigation]
```

### 6. セキュリティ設計

#### 6.1 認証情報管理
- GitHub Personal Access Token の安全な管理
- 環境変数による設定 (`GITHUB_TOKEN`, `ANTHROPIC_API_KEY`)
- Development/Production環境の分離

#### 6.2 Auto-Fix 安全性
- Git-based バックアップシステム
- Dry-run モードでの事前検証
- 自動ロールバック機能
- 修正対象ファイルの制限

### 7. エラーハンドリング設計

#### 7.1 統合エラー処理
```swift
enum IntegrationError: LocalizedError {
    case packageNotFound
    case configurationMissing
    case compatibilityIssue
    case rollbackRequired
    
    var errorDescription: String? {
        switch self {
        case .packageNotFound:
            return "共有パッケージが見つかりません"
        case .configurationMissing:
            return "設定が不完全です"
        case .compatibilityIssue:
            return "互換性の問題が発生しました"
        case .rollbackRequired:
            return "ロールバックが必要です"
        }
    }
}
```

#### 7.2 フォールバック戦略
- 共有パッケージ利用不可時は既存機能で継続
- Auto-Fix失敗時は従来の手動修正フローに戻る
- ネットワークエラー時はローカル保存機能を活用

### 8. テスト戦略

#### 8.1 統合テスト
- 既存機能の回帰テスト
- 新機能の動作確認テスト
- エラーケースのテスト

#### 8.2 段階的検証
- Phase 1: パッケージ追加のみでの動作確認
- Phase 2: バグレポート機能置き換え後の動作確認
- Phase 3: Auto-Fix機能追加後の総合確認

### 9. パフォーマンス設計

#### 9.1 最適化ポイント
- パッケージの遅延読み込み
- Watch mode のデバウンス処理
- Claude API の効率的な利用

#### 9.2 リソース管理
- メモリ使用量の監視
- CPU使用率の最適化
- ネットワーク通信の最小化

この設計により、安全かつ効率的にdelax-shared-packagesの先進機能をdelax100daysworkoutに統合できます。