#!/bin/bash

# Git pre-commitフックを設定するスクリプト

HOOKS_DIR=".git/hooks"
PRE_COMMIT_HOOK="$HOOKS_DIR/pre-commit"

# .gitディレクトリが存在するか確認
if [ ! -d ".git" ]; then
    echo "❌ Error: Not a git repository"
    exit 1
fi

# hooksディレクトリを作成
mkdir -p "$HOOKS_DIR"

# pre-commitフックを作成
cat > "$PRE_COMMIT_HOOK" << 'EOF'
#!/bin/bash

echo "🔍 Checking for secrets in staged files..."

# Pythonスクリプトを実行
python3 scripts/check_secrets.py --staged-only

if [ $? -ne 0 ]; then
    echo "❌ Pre-commit check failed!"
    echo "Please remove secrets before committing."
    exit 1
fi

echo "✅ Pre-commit check passed!"
exit 0
EOF

# 実行権限を付与
chmod +x "$PRE_COMMIT_HOOK"

echo "✅ Git pre-commit hook installed successfully!"
echo "The hook will check for secrets before each commit."