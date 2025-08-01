# 自動化ワークフローガイド

## 概要
このドキュメントでは、Delax100DaysWorkoutプロジェクトの自動化されたワークフローについて説明します。Issue作成からPRマージまでの一連の流れが自動化されています。

## 🔄 自動化されたワークフロー

### 1. Issue → 自動修正フロー
```
📝 Issue作成 → 🤖 Claude自動分析 → 🔧 コード修正 → 📤 PR自動作成
```

### 2. PR → 自動ビルドフロー  
```
📤 PR作成 → 🏗️ iOS自動ビルド → ✅/❌ 結果通知 → 🏷️ ラベル自動付与
```

### 3. 統合フロー
```
📱 通知受信 → 🔄 ローカル同期 → 🧪 動作確認 → 🚀 ワンクリックマージ
```

## 🛠️ 構成要素

### GitHub Actions ワークフロー

#### 1. Claude Code ワークフロー (`.github/workflows/claude.yml`)
- **トリガー**: Issue作成、PR作成、コメント投稿
- **機能**: 
  - 自動的なコード分析・修正
  - PR自動作成
  - OAuth認証でClaude Max使用

#### 2. iOS Build ワークフロー (`.github/workflows/ios-build.yml`)
- **トリガー**: PR作成・更新時
- **機能**:
  - macOS runner でXcodeビルド
  - iPhone 16 Pro/15 Pro Simulator対応
  - ビルド結果のPRコメント
  - 自動ラベル付与

### ローカルスクリプト

#### 1. PR同期スクリプト (`scripts/sync-pr.sh`)
```bash
# 使用方法
./scripts/sync-pr.sh <PR番号>

# 例
./scripts/sync-pr.sh 30
```

**機能**:
- PR情報の自動取得
- ローカルブランチ同期
- Xcodeビルド＆テスト
- インタラクティブマージ

#### 2. 通知システム (`scripts/notify.sh`)
```bash
# 使用方法
./scripts/notify.sh <通知タイプ> <番号>

# 例
./scripts/notify.sh pr-created 30
./scripts/notify.sh build-success 30
./scripts/notify.sh ready-to-merge 30
```

**対応通知**:
- macOS通知
- Slack通知（SLACK_WEBHOOK_URL設定時）
- メール通知（NOTIFICATION_EMAIL設定時）

## 📱 実際の使用フロー

### シナリオ1: バグ修正
1. **Issue作成** → Claude が自動で分析・修正・PR作成
2. **通知受信** → 「PR作成完了」通知
3. **自動ビルド** → iOS ビルドが自動実行
4. **ローカル確認** → `./scripts/sync-pr.sh 30` で同期・テスト
5. **マージ** → スクリプト内でワンクリックマージ

### シナリオ2: 新機能追加
1. **Issue作成** → Claude が実装・PR作成
2. **ビルド通知** → 成功/失敗の通知受信
3. **コードレビュー** → PRページで差分確認
4. **動作確認** → ローカルで実際にテスト
5. **マージ** → 問題なければマージ実行

## ⚙️ 設定方法

### 1. 必須設定
- **GitHub Secrets**:
  - `CLAUDE_ACCESS_TOKEN`
  - `CLAUDE_REFRESH_TOKEN` 
  - `CLAUDE_EXPIRES_AT`

### 2. オプション設定
- **Slack通知**: 環境変数 `SLACK_WEBHOOK_URL`
- **メール通知**: 環境変数 `NOTIFICATION_EMAIL`

### 3. ローカル設定
```bash
# スクリプトに実行権限付与
chmod +x scripts/*.sh

# GitHub CLI認証確認
gh auth status
```

## 🏷️ 自動ラベル

### PR作成時
- `✅ Ready to merge` - ビルド成功時
- `❌ Build failed` - ビルド失敗時
- `iOS build passed` - iOS ビルド成功
- `needs-fix` - 修正が必要

### Issue作成時
- `auto-processing` - Claude処理中
- `auto-fixed` - 自動修正完了

## 🔧 トラブルシューティング

### ビルドエラーの場合
1. **エラーログ確認**: `error/Build_PR<番号>_<日時>.txt`
2. **GitHub Actionsログ**: PRページの「Checks」タブ
3. **ローカルビルド**: `./build.sh` で直接確認

### Claude処理エラーの場合
1. **OAuth認証確認**: シークレット設定を確認
2. **アクション権限**: リポジトリ権限を確認
3. **再実行**: PR/Issueに新しいコメント投稿

### 通知が届かない場合
1. **macOS通知**: システム環境設定で通知許可確認
2. **Slack通知**: Webhook URL設定確認
3. **手動テスト**: `./scripts/notify.sh pr-created 30`

## 📊 ワークフロー監視

### GitHub Actions
- **実行履歴**: Actions タブで確認
- **ビルド時間**: 通常5-10分
- **成功率**: ダッシュボードで監視

### パフォーマンス指標
- **Issue → PR作成**: 平均3-5分
- **PR → ビルド完了**: 平均5-8分
- **通知 → ローカル同期**: 1-2分

## 🚀 今後の拡張

### 計画中の機能
- **自動テスト実行**: Unit Test/UI Test
- **App Store Connect連携**: TestFlight自動配布
- **品質メトリクス**: コードカバレッジ・複雑度測定
- **セキュリティスキャン**: 脆弱性自動検出

### カスタマイズ例
- **独自通知チャンネル**: Discord/Teams連携
- **レビュー自動化**: PR自動レビュー
- **デプロイ自動化**: staging環境自動デプロイ

---

## 🆘 サポート

このワークフローについて質問がある場合は、Issueを作成してください。Claude が自動的に回答します！

**例**: 「ワークフローの設定方法を教えて」「ビルドエラーを修正して」