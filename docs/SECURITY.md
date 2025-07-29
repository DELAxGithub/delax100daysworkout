# セキュリティガイド

## APIキー・トークンの管理

### 重要な注意事項

**絶対にAPIキーやトークンをコードに直接書き込まないでください！**

### 設定方法

#### 1. ローカル開発環境

1. `.env.example`をコピーして`.env`を作成
   ```bash
   cp .env.example .env
   ```

2. `.env`ファイルを編集して実際のトークンを設定
   ```
   GITHUB_TOKEN=gho_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   CLAUDE_API_KEY=sk-ant-apixx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   ```

3. **重要**: `.env`ファイルは絶対にコミットしないでください（.gitignoreに登録済み）

#### 2. Xcode での実行

Xcodeから環境変数を設定する場合：

1. Xcode > Product > Scheme > Edit Scheme
2. Run > Arguments > Environment Variables
3. 以下を追加：
   - `GITHUB_TOKEN`: あなたのGitHubトークン
   - `CLAUDE_API_KEY`: あなたのClaude APIキー

#### 3. GitHub Actions（CI/CD）

1. GitHubリポジトリの Settings > Secrets and variables > Actions
2. New repository secret で以下を追加：
   - `GITHUB_TOKEN`
   - `CLAUDE_API_KEY`

### トークンの取得方法

#### GitHub Personal Access Token

1. https://github.com/settings/tokens にアクセス
2. "Generate new token (classic)" をクリック
3. 必要なスコープを選択：
   - `repo` - リポジトリへのフルアクセス（Issue作成に必要）
4. トークンを生成して安全に保管

#### Claude API Key

1. https://console.anthropic.com/ にアクセス
2. APIキーを生成
3. 安全に保管

### セキュリティチェック

コミット前の自動チェックを有効化：

```bash
./scripts/setup_git_hooks.sh
```

手動でチェック：

```bash
python3 scripts/check_secrets.py
```

### もしトークンを誤って公開してしまったら

1. **即座に**該当するトークンを無効化
2. 新しいトークンを生成
3. 影響を受ける可能性のあるシステムを確認
4. 必要に応じてセキュリティ監査を実施

### ベストプラクティス

1. トークンには最小限の権限のみを付与
2. 定期的にトークンをローテーション
3. 使用していないトークンは削除
4. トークンの使用状況を監視
5. 2要素認証を有効化