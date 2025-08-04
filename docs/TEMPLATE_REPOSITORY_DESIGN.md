# Claude開発ワークフロー - テンプレートリポジトリ設計

## 🎯 テンプレートリポジトリ: `claude-dev-workflow-template`

新プロジェクトで即座に高効率開発ワークフローを構築できるテンプレートリポジトリの設計仕様。

## 📁 完全なディレクトリ構造

```
claude-dev-workflow-template/
├── README.md                           # メインドキュメント
├── TEMPLATE_USAGE.md                   # テンプレート使用方法
├── setup.sh                           # ワンコマンドセットアップ
├── .github/
│   ├── workflows/
│   │   ├── claude.yml.template         # Claude自動修正（汎用版）
│   │   └── code-check.yml.template     # コードチェック（汎用版）
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml              # バグレポート
│   │   ├── feature_request.yml         # 機能要求
│   │   └── config.yml                  # Issue設定
│   └── PULL_REQUEST_TEMPLATE.md        # PRテンプレート
├── scripts/                           # 汎用スクリプト群（完全移植）
│   ├── quick-pull.sh                   # 手動プル
│   ├── auto-pull.sh                    # 自動プル監視
│   ├── sync-pr.sh                      # PR同期
│   ├── notify.sh                       # 通知システム
│   └── utils/                          # ユーティリティ
│       ├── config-loader.sh            # 設定読み込み
│       └── git-utils.sh                # Git操作共通関数
├── templates/                         # 言語・フレームワーク別テンプレート
│   ├── ios-swift/                      # iOS Swift専用
│   │   ├── README.md                   # iOS固有説明
│   │   ├── build.sh.template           # Xcodeビルドスクリプト
│   │   ├── .github/
│   │   │   └── workflows/
│   │   │       └── ios-code-check.yml  # Swift構文チェック
│   │   ├── docs/
│   │   │   ├── XCODE_SETUP.md         # Xcode設定
│   │   │   └── WORKFLOW_GUIDE.md      # iOS用ワークフロー
│   │   └── config/
│   │       └── ios-config.yml          # iOS固有設定
│   ├── react-typescript/              # React TypeScript
│   │   ├── README.md
│   │   ├── package.json.template
│   │   ├── .github/
│   │   │   └── workflows/
│   │   │       └── react-code-check.yml
│   │   └── config/
│   │       └── react-config.yml
│   ├── python-django/                 # Python Django
│   │   ├── README.md
│   │   ├── requirements.txt.template
│   │   ├── .github/
│   │   │   └── workflows/
│   │   │       └── python-code-check.yml
│   │   └── config/
│   │       └── python-config.yml
│   └── go-cli/                        # Go CLI ツール
│       ├── README.md
│       ├── go.mod.template
│       ├── .github/
│       │   └── workflows/
│       │       └── go-code-check.yml
│       └── config/
│           └── go-config.yml
├── config/                            # 共通設定ファイル
│   ├── workflow-config.yml.example     # ワークフロー設定例
│   ├── notification-config.yml.example # 通知設定例
│   └── project-types.yml              # 対応プロジェクト種別
├── docs/                              # ドキュメント
│   ├── SETUP_GUIDE.md                 # 詳細セットアップ
│   ├── WORKFLOW_GUIDE.md              # 運用ガイド
│   ├── CUSTOMIZATION_GUIDE.md         # カスタマイズ方法
│   ├── TROUBLESHOOTING.md             # トラブルシューティング
│   └── MIGRATION_GUIDE.md             # 既存プロジェクト移行
└── examples/                          # 実例
    ├── delax100daysworkout/           # 実際の成功例
    │   ├── README.md                  # 実装例説明
    │   └── workflow-screenshots/      # 動作画面
    └── sample-projects/               # サンプルプロジェクト
        ├── sample-ios-app/
        ├── sample-react-app/
        └── sample-python-api/
```

## 🚀 セットアップスクリプト設計

### `setup.sh` - メインセットアップスクリプト

```bash
#!/bin/bash
# Claude開発ワークフロー - ワンコマンドセットアップ

Usage:
  ./setup.sh <project-type> [options]

Project Types:
  ios-swift        iOS Swift + Xcode プロジェクト
  react-typescript React + TypeScript プロジェクト  
  python-django    Python + Django API
  go-cli           Go CLI ツール

Options:
  --with-auto-pull    自動プル監視も設定
  --slack-webhook URL Slack通知設定
  --dry-run          設定内容のプレビューのみ

Examples:
  ./setup.sh ios-swift
  ./setup.sh react-typescript --with-auto-pull
  ./setup.sh ios-swift --slack-webhook https://hooks.slack.com/...
```

## 📋 各テンプレートの特化機能

### iOS Swift テンプレート
**対応技術スタック**:
- Xcode + SwiftUI
- ClaudeKit連携
- iOS Simulator対応
- TestFlight準備

**含まれるファイル**:
```
templates/ios-swift/
├── build.sh.template              # Xcodeビルド
├── .github/workflows/
│   └── ios-code-check.yml         # Swift構文・Import・括弧チェック
├── scripts/
│   └── ios-setup.sh               # iOS固有セットアップ
└── docs/
    ├── XCODE_INTEGRATION.md       # Xcode連携方法
    └── CLAUDEKIT_SETUP.md         # ClaudeKit設定
```

### React TypeScript テンプレート
**対応技術スタック**:
- React + TypeScript
- ESLint + Prettier
- Jest + Testing Library
- Vercel/Netlify対応

### Python Django テンプレート
**対応技術スタック**:
- Django + DRF
- Black + flake8
- pytest
- Docker対応

### Go CLI テンプレート
**対応技術スタック**:
- Go modules
- Cobra CLI
- gofmt + golint
- バイナリリリース

## 🔧 設定システム設計

### `config/workflow-config.yml.example`
```yaml
# Claude開発ワークフロー設定
project:
  name: "my-awesome-project"
  type: "ios-swift"  # ios-swift, react-typescript, python-django, go-cli
  language: "swift"
  
github:
  main_branch: "main"
  pr_auto_merge: false
  
build:
  command: "./build.sh"
  timeout: 300
  
notifications:
  slack:
    enabled: false
    webhook_url: "${SLACK_WEBHOOK_URL}"
  email:
    enabled: false
    recipient: "${NOTIFICATION_EMAIL}"
  macos:
    enabled: true
    
claude:
  oauth_enabled: true
  auto_trigger: true  # @claude mention不要
  
scripts:
  auto_pull:
    enabled: false  # デフォルトは手動プル推奨
    interval: 30    # 秒
```

## 🎯 使用フロー設計

### 1. テンプレートからプロジェクト作成
```bash
gh repo create my-new-project --template claude-dev-workflow-template
cd my-new-project
```

### 2. ワンコマンドセットアップ
```bash
./setup.sh ios-swift
```

### 3. GitHub Secrets設定
```bash
# セットアップスクリプトが自動生成する設定コマンド
gh secret set CLAUDE_ACCESS_TOKEN
gh secret set CLAUDE_REFRESH_TOKEN  
gh secret set CLAUDE_EXPIRES_AT
```

### 4. 即座に利用開始
```bash
# Issue作成 → Claude自動修正・PR作成
# マージ後
./scripts/quick-pull.sh
# → Xcodeでテスト
```

## 📊 各言語テンプレートの差分

| 機能 | iOS Swift | React TS | Python | Go |
|------|----------|----------|---------|-----|
| 基本スクリプト | ✅ 共通 | ✅ 共通 | ✅ 共通 | ✅ 共通 |
| Claude Actions | ✅ 共通 | ✅ 共通 | ✅ 共通 | ✅ 共通 |
| 通知システム | ✅ 共通 | ✅ 共通 | ✅ 共通 | ✅ 共通 |
| コードチェック | Swift構文 | ESLint | flake8 | gofmt |
| ビルドコマンド | xcodebuild | npm build | python manage.py | go build |
| テストコマンド | XCTest | Jest | pytest | go test |
| 依存管理 | Xcode | package.json | requirements.txt | go.mod |

## 🏆 期待される効果

### 開発開始時間の短縮
- **従来**: 1-2週間（ワークフロー構築）
- **テンプレート使用後**: 30分（セットアップ完了）

### 品質保証の標準化
- 実績あるワークフローの即座適用
- エラーハンドリング完備
- ベストプラクティスの自動適用

### 学習コストの削減
- 統一されたコマンド体系
- 共通ドキュメント
- 一貫した運用方法

---

**このテンプレートリポジトリにより、今回構築した高効率ワークフローが任意のプロジェクトで即座に利用可能になります。**