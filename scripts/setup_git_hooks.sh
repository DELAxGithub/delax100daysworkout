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

echo "🔍 Running enterprise pre-commit validation..."

# Phase 1: Security Check
echo "🔒 Checking for secrets..."
python3 scripts/check_secrets.py --staged-only
if [ $? -ne 0 ]; then
    echo "❌ Security check failed!"
    exit 1
fi

# Phase 2: Swift Syntax Check
echo "🔨 Validating Swift syntax..."
STAGED_SWIFT=$(git diff --cached --name-only --diff-filter=ACM | grep '\.swift$')
if [ -n "$STAGED_SWIFT" ]; then
    for file in $STAGED_SWIFT; do
        if [ -f "$file" ]; then
            # Quick syntax check
            xcrun swiftc -typecheck "$file" 2>/dev/null
            if [ $? -ne 0 ]; then
                echo "❌ Swift syntax error in: $file"
                exit 1
            fi
        fi
    done
    echo "✅ Swift syntax validation passed"
fi

# Phase 3: Build Safety Check (Quick)
echo "🏗️ Quick build validation..."
if [ -f "Delax100DaysWorkout.xcodeproj/project.pbxproj" ]; then
    # Test if project can be parsed
    xcodebuild -list -project Delax100DaysWorkout.xcodeproj >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "❌ Project configuration corrupted!"
        exit 1
    fi
    echo "✅ Project structure validated"
fi

echo "✅ All pre-commit checks passed!"
exit 0
EOF

# 実行権限を付与
chmod +x "$PRE_COMMIT_HOOK"

echo "✅ Git pre-commit hook installed successfully!"
echo "The hook will check for secrets before each commit."