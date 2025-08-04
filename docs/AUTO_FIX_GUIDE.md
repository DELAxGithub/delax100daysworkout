# 🔧 Auto-Fix機能ガイド

Delax100DaysWorkoutプロジェクトに統合されたiOS Auto-Fix機能の使用方法です。

## ✨ 機能概要

- 🤖 **AI自動修正**: Claude 4 Sonnetによるビルドエラーの自動解析・修正
- 🔄 **Watch Mode**: ファイル変更の継続的監視と自動修正
- 🛡️ **安全な修正**: Git-basedバックアップシステム
- 📊 **GitHub統合**: CI/CDでの自動修正とIssue作成

## 🚀 使用方法

### 1. 環境準備

```bash
# Claude API キーの設定
export ANTHROPIC_API_KEY="your-api-key-here"

# GitHub Secretsに設定（CI/CD用）
# ANTHROPIC_API_KEY: Claude APIキー
# GITHUB_TOKEN: 自動的に設定済み
```

### 2. 一回限りの修正

```bash
# 現在のビルドエラーを修正
./auto-fix-scripts/auto-build-fix.sh
```

### 3. Watch Mode（継続監視）

```bash
# ファイル変更を監視して自動修正
./watch-mode.sh
```

### 4. GitHub Actions（自動CI/CD）

- Swiftファイルの変更をpushすると自動的に実行
- ビルドエラーがあれば自動修正してcommit
- 修正失敗時は自動的にIssueを作成

## ⚙️ 設定

### auto-fix-config.yml

```yaml
project:
  name: "Delax100DaysWorkout"
  xcode_project: "Delax100DaysWorkout.xcodeproj"
  scheme: "Delax100DaysWorkout"

build:
  max_attempts: 5
  timeout_seconds: 300

claude:
  model: "claude-4-sonnet-20250514"

watch:
  directories:
    - "Delax100DaysWorkout/Models"
    - "Delax100DaysWorkout/Features"
    - "Delax100DaysWorkout/Services"
  debounce_seconds: 3
```

## 🛡️ 安全機能

### Git-based バックアップ
- 修正前に自動的にgit stash
- 修正失敗時の自動ロールバック
- 変更履歴の完全な追跡

### 修正制限
- 設定ファイルで指定されたディレクトリのみ
- プロジェクトファイル(.pbxproj)は除外
- ユーザーデータは変更しない

## 📊 対応エラータイプ

- ✅ Swift Compiler Errors
- ✅ SwiftUI 関連問題
- ✅ Import/Module エラー
- ✅ Build System 問題
- ✅ Code Signing 問題（基本的な修正）

## 🔧 トラブルシューティング

### Watch Mode が起動しない

```bash
# 権限確認
ls -la ./auto-fix-scripts/
chmod +x ./auto-fix-scripts/*.sh

# API キー確認
echo $ANTHROPIC_API_KEY
```

### GitHub Actions で失敗する

1. **Secrets確認**: `ANTHROPIC_API_KEY`が設定されているか
2. **権限確認**: リポジトリの`Actions`権限が有効か
3. **ログ確認**: Actions タブでエラーログを確認

### 修正が適用されない

```bash
# 現在の状態確認
git status

# 手動でstash確認
git stash list

# 手動ロールバック
git stash pop
```

## 💡 ベストプラクティス

1. **重要な変更前**: 手動でgit commitしてからAuto-Fixを使用
2. **Watch Mode**: 開発中は継続的に実行
3. **レビュー**: Auto-Fixの修正内容は必ず確認
4. **バックアップ**: 重要なコードは定期的にバックアップ

## 📈 統計とモニタリング

Auto-Fix機能の使用状況は以下で確認できます：

- GitHub Actions の実行履歴
- コミットログの`🔧 Auto-fix:`プレフィックス
- 自動作成されるIssue（修正失敗時）

---

**Claude AI Integration**: このシステムはClaude 4 Sonnetの知能を活用しています 🤖