# iOS開発向け現実的ワークフローガイド

## 概要
このドキュメントでは、Delax100DaysWorkoutプロジェクトの現実的で効率的な自動化ワークフローについて説明します。iOS開発の特殊性を考慮し、完全自動化よりも「効率的な半自動化」を採用しています。

## 🔄 新しい現実的ワークフロー

### 1. Issue → 自動修正フロー
```
📝 Issue作成 → 🤖 Claude自動分析 → 🔧 コード修正 → 📤 PR自動作成
```

### 2. PR → 軽量チェックフロー  
```
📤 PR作成 → 🔍 基本チェック(3分) → ✅ レビュー準備完了通知
```

### 3. 手動マージ → 手動同期フロー（推奨）
```
👤 手動マージ → 📥 手動プル → 🧪 Xcodeビルド推奨通知 → 🔨 手動テスト
```

## 🛠️ 構成要素

### GitHub Actions ワークフロー

#### 1. Claude Code ワークフロー (`.github/workflows/claude.yml`)
- **トリガー**: Issue作成、PR作成、コメント投稿
- **機能**: 
  - 自動的なコード分析・修正
  - PR自動作成
  - OAuth認証でClaude Max使用

#### 2. PR Code Check ワークフロー (`.github/workflows/ios-build.yml`)
- **トリガー**: PR作成・更新時
- **機能**:
  - Ubuntu runner で軽量チェック（3分以内）
  - Swift構文チェック・Import文確認
  - 括弧バランスチェック
  - レビュー準備完了通知・ラベル付与
  - ❌ **iOS実機ビルドは実行しない**（エラー回避・時間短縮）

### ローカルスクリプト

#### 1. 手動プルコマンド (`scripts/quick-pull.sh`) ⭐ NEW
```bash
# 使用方法（マージ後に実行）
./scripts/quick-pull.sh
```

**機能**:
- ワンコマンドでプル＋通知
- 変更内容の事前確認
- プル完了→Xcodeビルド推奨通知
- エラーハンドリング・安全チェック

#### 2. 自動プルシステム (`scripts/auto-pull.sh`) 📦 オプション
```bash
# 使用方法（必要時のみ）
./scripts/auto-pull.sh start          # 監視開始（バックグラウンド）
./scripts/auto-pull.sh stop           # 監視停止
```

**機能**:
- バックグラウンド監視（システム負荷考慮でオプション機能）
- マージ検知とgit pull自動実行

#### 3. PR同期スクリプト (`scripts/sync-pr.sh`) 📦 オプション
```bash
# 使用方法（任意利用）
./scripts/sync-pr.sh <PR番号>

# 例
./scripts/sync-pr.sh 30
```

**機能**:
- PR情報の自動取得
- ローカルブランチ同期
- Xcodeビルド＆テスト
- インタラクティブマージ

#### 4. 通知システム (`scripts/notify.sh`) 🔄 UPDATED
```bash
# 使用方法
./scripts/notify.sh <通知タイプ> <番号>

# 新しい通知タイプ
./scripts/notify.sh merge-completed 30    # マージ完了
./scripts/notify.sh merge-pulled abc1234  # プル完了
./scripts/notify.sh xcode-recommended     # Xcodeビルド推奨
```

**対応通知**:
- macOS通知
- Slack通知（SLACK_WEBHOOK_URL設定時）
- メール通知（NOTIFICATION_EMAIL設定時）

## 📱 新しい使用フロー

### 🚀 推奨シナリオ: Issue修正の完全フロー
1. **Issue作成** → Claude が自動で分析・修正・PR作成（5分）
2. **軽量チェック** → GitHub Actions で基本チェック（3分）
3. **レビュー・マージ** → 手動でコードレビュー・マージ実行
4. **手動プル** → `./scripts/quick-pull.sh` で同期＋通知（1分）
5. **Xcodeテスト** → 通知受信後、手動でビルド・実機テスト

### ⚡ 高速シナリオ: 軽微な修正
1. **Issue作成** → Claude修正・PR作成
2. **即座にマージ** → チェック完了を待たずにマージ
3. **手動プル** → `./scripts/quick-pull.sh` で即座同期
4. **実機確認** → Xcodeで最終確認

### 🔧 カスタムシナリオ: PR同期スクリプト利用
1. **手動PR確認** → `./scripts/sync-pr.sh 30` で同期・テスト
2. **ローカルテスト** → Xcodeビルド・実機テスト実行
3. **マージ判断** → スクリプト内でインタラクティブマージ

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

# テスト実行（手動プルコマンド）
./scripts/quick-pull.sh
```

### 4. 基本的な使い方
```bash
# マージ後にこのコマンドを実行
./scripts/quick-pull.sh

# オプション: 自動プル監視（必要時のみ）
./scripts/auto-pull.sh start    # 開始
./scripts/auto-pull.sh stop     # 停止

# テスト通知
./scripts/notify.sh xcode-recommended
```

## 🏷️ 自動ラベル

### PR作成時
- `✅ Code check passed` - 基本チェック成功時
- `Ready for review` - レビュー準備完了
- `❌ Code check failed` - チェック失敗時
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
- **PR → チェック完了**: 平均2-3分 ⚡（大幅短縮）
- **マージ → 手動プル実行**: 1分以内 🚀（ワンコマンド）
- **プル → Xcodeビルド開始**: 即座
- **システム負荷**: 0%（手動実行時のみ）

## 🚀 今後の拡張

### 完了した機能 ✅
- **軽量チェック**: iOSビルドエラー回避・高速化
- **手動プルコマンド**: ワンコマンドでプル・通知・Xcodeビルド推奨
- **通知拡張**: マージ・プル・Xcodeビルド推奨
- **現実的ワークフロー**: システム負荷ゼロでiOS開発に最適化

### 将来の拡張案（必要に応じて）
- **TestFlight自動配布**: 開発者アカウント使用時
- **品質メトリクス**: SwiftLint連携
- **セキュリティスキャン**: 静的解析ツール連携

### カスタマイズ例
- **独自通知チャンネル**: Discord/Teams連携
- **レビュー自動化**: PR自動レビュー
- **デプロイ自動化**: staging環境自動デプロイ

---

## 📊 ワークフロー比較

| 項目 | 旧ワークフロー | 新ワークフロー |
|------|-------------|-------------|
| PR作成後の待機時間 | 15分（iOSビルド） | 3分（軽量チェック） |
| エラー発生率 | 高（iOS環境依存） | 低（基本チェックのみ） |
| ローカル同期 | 手動git pull | ワンコマンド手動実行 |
| 実機テスト | GitHub Actions | ローカルXcode |
| システム負荷 | 中程度 | 0%（手動実行時のみ） |
| 開発効率 | 中程度 | 高効率 ⚡ |

## 🆘 サポート

このワークフローについて質問がある場合は、Issueを作成してください。Claude が自動的に回答します！

**例**: 
- 「quick-pull.sh の使い方を教えて」
- 「通知が届かない問題を修正して」
- 「手動プルワークフローの使い方を説明して」