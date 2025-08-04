# GitHub リポジトリセットアップガイド

## 1. Git初期化とリモート設定

```bash
# プロジェクトディレクトリで実行
cd /Users/delax/repos/delax100daysworkout

# Git初期化
git init

# リモートリポジトリを追加
git remote add origin https://github.com/DELAxGithub/delax100daysworkout.git

# 現在の状態を確認
git status
```

## 2. 必要なファイルをコミット

```bash
# .gitignoreを追加
git add .gitignore

# GitHub Actions ワークフローを追加
git add .github/workflows/auto-fix-bug.yml
git add .github/ISSUE_TEMPLATE/bug_report.yml

# Python スクリプトを追加
git add scripts/analyze_issue.py
git add scripts/generate_fix.py
git add scripts/apply_fix.py
git add scripts/safety_rules.json

# ドキュメントを追加
git add doc/auto-fix-feature.md
git add doc/environment-setup.md
git add README.md  # もしあれば

# 初回コミット
git commit -m "Add auto-fix bug feature with GitHub Actions

- Add GitHub Actions workflow for automatic bug fixing
- Add Python scripts for issue analysis and code generation
- Add safety rules configuration
- Add documentation"

# mainブランチに名前を変更（必要な場合）
git branch -M main

# GitHubにプッシュ
git push -u origin main
```

## 3. GitHub Secretsの設定

1. ブラウザで https://github.com/DELAxGithub/delax100daysworkout を開く
2. Settings タブをクリック
3. 左側メニューから "Secrets and variables" → "Actions" を選択
4. "New repository secret" をクリック
5. 以下を追加：
   - Name: `CLAUDE_API_KEY`
   - Value: `y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`

## 4. ラベルの設定

GitHubリポジトリで以下のラベルを作成：

1. Issues タブを開く
2. Labels をクリック
3. 以下のラベルを追加（もし存在しなければ）：
   - `auto-fix-candidate` (色: #0E8A16 緑)
   - `auto-generated` (色: #FBCA04 黄)
   - `ui-bug` (色: #D73A4A 赤)

## 5. 動作確認

1. 既存のIssueに `auto-fix-candidate` ラベルを手動で追加
2. Actions タブで自動修正ワークフローが開始されることを確認

## 注意事項

- `.env` ファイルは絶対にコミットしない（.gitignoreに含まれているはず）
- トークンやAPIキーは GitHub Secrets でのみ管理
- 初回はテスト用のシンプルなバグで動作確認することを推奨