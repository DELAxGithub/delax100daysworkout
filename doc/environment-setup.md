# 環境変数設定ガイド

## 概要

Delax100DaysWorkoutアプリの全機能を使用するには、いくつかの環境変数の設定が必要です。このガイドでは、各環境変数の設定方法を説明します。

## 必要な環境変数

### 1. アプリ内バグ報告機能

アプリからGitHub Issueを作成するために必要：

- `GITHUB_OWNER`: GitHubリポジトリのオーナー名
- `GITHUB_REPO`: リポジトリ名
- `GITHUB_TOKEN`: GitHub Personal Access Token

### 2. 自動バグ修正機能

GitHub Actionsで自動修正を実行するために必要：

- `CLAUDE_API_KEY`: Anthropic Claude APIのキー
- `GITHUB_TOKEN`: GitHub Actions用（自動的に提供される）

## 設定方法

### ローカル開発環境

#### 1. Xcodeでの設定

1. Xcode でプロジェクトを開く
2. ターゲットを選択 → "Edit Scheme"
3. "Run" → "Arguments" → "Environment Variables"
4. 以下を追加：

```
GITHUB_OWNER = your-github-username
GITHUB_REPO = delax100daysworkout
GITHUB_TOKEN = your-personal-access-token
```

#### 2. .env ファイルの使用（非推奨）

セキュリティ上の理由から推奨されませんが、開発時は以下も可能：

```bash
# .env.local（.gitignoreに追加済み）
GITHUB_OWNER=your-github-username
GITHUB_REPO=delax100daysworkout
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx
```

### GitHub Actions（本番環境）

#### 1. GitHub Secretsの設定

1. GitHubリポジトリのページを開く
2. Settings → Secrets and variables → Actions
3. "New repository secret" をクリック
4. 以下のシークレットを追加：

##### CLAUDE_API_KEY

1. [Anthropic Console](https://console.anthropic.com/)にアクセス
2. API Keysセクションで新しいキーを作成
3. キーをコピーしてGitHub Secretsに追加

```
Name: CLAUDE_API_KEY
Value: sk-ant-api03-xxxxxxxxxxxx
```

##### GITHUB_TOKEN（追加設定不要）

GitHub Actionsでは`GITHUB_TOKEN`が自動的に提供されます。追加設定は不要です。

#### 2. Personal Access Token（アプリ用）

アプリからGitHub APIを使用するための設定：

1. GitHub → Settings → Developer settings
2. Personal access tokens → Tokens (classic)
3. "Generate new token" をクリック
4. 権限を設定：
   - `repo` (Full control of private repositories)
   - `workflow` (Update GitHub Action workflows)
5. トークンを生成してコピー

### 環境変数の確認

#### ローカルでの確認

```swift
// EnvironmentConfig.swift
struct EnvironmentConfig {
    static let githubOwner = ProcessInfo.processInfo.environment["GITHUB_OWNER"] ?? "default-owner"
    static let githubRepo = ProcessInfo.processInfo.environment["GITHUB_REPO"] ?? "default-repo"
    static let githubToken = ProcessInfo.processInfo.environment["GITHUB_TOKEN"]
}
```

#### GitHub Actionsでの確認

```yaml
- name: Check environment
  run: |
    if [ -z "$CLAUDE_API_KEY" ]; then
      echo "CLAUDE_API_KEY is not set"
      exit 1
    fi
    echo "Environment variables are properly set"
  env:
    CLAUDE_API_KEY: ${{ secrets.CLAUDE_API_KEY }}
```

## セキュリティのベストプラクティス

### DO ✅

1. **GitHub Secretsを使用**
   - 本番環境では必ずGitHub Secretsを使用
   - ローカルではXcodeのScheme設定を使用

2. **最小権限の原則**
   - トークンには必要最小限の権限のみ付与
   - 定期的に権限を見直す

3. **ローテーション**
   - APIキーとトークンを定期的に更新
   - 漏洩の疑いがある場合は即座に無効化

### DON'T ❌

1. **ハードコーディング禁止**
   ```swift
   // 絶対にやってはいけない例
   let token = "ghp_xxxxxxxxxxxx" // ❌
   ```

2. **コミットに含めない**
   - .envファイルをコミットしない
   - APIキーを含むファイルは.gitignoreに追加

3. **ログに出力しない**
   ```swift
   // やってはいけない例
   print("Token: \(token)") // ❌
   ```

## トラブルシューティング

### 問題: "GitHubトークンが設定されていません"

**解決方法:**
1. 環境変数が正しく設定されているか確認
2. Xcodeを再起動
3. Schemeの設定を確認

### 問題: "Issueの作成に失敗しました"

**解決方法:**
1. トークンの権限を確認（repoスコープが必要）
2. リポジトリ名とオーナー名が正しいか確認
3. トークンの有効期限を確認

### 問題: GitHub Actionsが失敗する

**解決方法:**
1. Secretsが正しく設定されているか確認
2. ワークフローのログを確認
3. APIキーの有効性を確認

## 参考リンク

- [GitHub Personal Access Tokens](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Anthropic API Documentation](https://docs.anthropic.com/claude/reference/getting-started-with-the-api)
- [Xcode Environment Variables](https://developer.apple.com/documentation/xcode/customizing-the-build-schemes-for-a-project)

## チェックリスト

開発開始前に以下を確認：

- [ ] GitHub Personal Access Tokenを作成した
- [ ] XcodeのSchemeに環境変数を設定した
- [ ] ローカルでバグ報告機能が動作することを確認した
- [ ] GitHub Secretsを設定した（本番環境用）
- [ ] .gitignoreに機密ファイルが含まれていることを確認した