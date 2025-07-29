# Delax 100 Days Workout

総合的なフィットネストレーニングアプリ。サイクリング、筋トレ、柔軟性トレーニングを統合管理。

## プロジェクト構造

```
/Users/delax/repos/delax100daysworkout/
├── Delax100DaysWorkout.xcodeproj/      # Xcodeプロジェクト
├── Delax100DaysWorkout/                 # アプリソースコード
│   ├── Models/                          # データモデル
│   ├── Features/                        # 画面・機能
│   ├── Services/                        # ビジネスロジック
│   └── Application/                     # アプリ設定
├── docs/                                # ドキュメント
│   ├── README.md                        # このファイル
│   ├── progress.md                      # 開発進捗
│   ├── training_template_requirements_v2.md  # 要件定義v2
│   └── specs/                           # 設計書
│       ├── extend-training-app/         # 初期仕様
│       └── auto-bug-fix/                # 自動バグ修正システム
├── scripts/                             # 自動化スクリプト
│   ├── add_to_xcode.py                 # Xcodeプロジェクト更新
│   └── update_xcode_project.sh         # 一括更新
└── error/                               # ビルドエラーログ

```

## 主要機能

### 1. 今日のタスク（TodayView）
- その日のトレーニングを自動提案
- ワンタップで完了記録
- 進捗の可視化

### 2. トレーニング種別
- **サイクリング**: FTP向上、持久力強化
- **筋トレ**: Push/Pull/Legs分割
- **柔軟性**: 前屈、開脚の記録管理

### 3. インテリジェント機能
- パフォーマンスに基づく自動調整
- PR（Personal Record）の検出
- モチベーショナルメッセージ

## 開発環境

- **言語**: Swift 5.9
- **UI**: SwiftUI
- **データ**: SwiftData
- **最小OS**: iOS 17.0

## ビルド方法

### Xcodeから
1. `Delax100DaysWorkout.xcodeproj`を開く
2. ターゲットデバイスを選択
3. Cmd+R でビルド実行

### VS Codeから
```bash
./build.sh
```

## ドキュメント

- [開発進捗](progress.md)
- [要件定義v2](training_template_requirements_v2.md)
- [設計書](specs/)

## セットアップ

### 環境変数の設定

1. **ローカル開発環境**
   ```bash
   cp .env.example .env
   # .envファイルを編集して、実際のトークンを設定
   ```

2. **GitHub Secrets（GitHub Actions用）**
   - リポジトリの Settings > Secrets and variables > Actions
   - 以下のシークレットを追加：
     - `GITHUB_TOKEN`: GitHub Personal Access Token
     - `CLAUDE_API_KEY`: Anthropic Claude API Key

### セキュリティフックの設定

```bash
# Git pre-commitフックをインストール
./scripts/setup_git_hooks.sh
```

これにより、コミット時に自動的に秘密情報のチェックが行われます。

## 機能

### 自動バグ修正システム

1. **バグ報告**: アプリ内でシェイクジェスチャー（3回振る）でバグ報告画面を表示
2. **Issue作成**: GitHub Issueが自動的に作成される
3. **自動分析**: Claude AIがIssueを分析し、修正可能か判定
4. **自動修正**: 簡単なバグは自動的にPRが作成される

## 今後の展望

1. 週番号による動的テンプレート
2. ソーシャル機能の追加
3. より高度な自動修正機能