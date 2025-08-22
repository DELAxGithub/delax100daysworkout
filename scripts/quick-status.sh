#!/bin/bash

# 🚀 Quick Status - プロジェクト現状を3分で把握するスクリプト
# Usage: ./scripts/quick-status.sh [--full]

echo "📊 Delax 100 Days Workout - Project Status Dashboard"
echo "================================================="
echo ""

# Git情報表示
echo "🔧 Git Status:"
echo "Current Branch: $(git branch --show-current)"
echo "Last Commit: $(git log -1 --pretty=format:'%h - %s (%cr)' 2>/dev/null || echo 'No commits')"
echo ""

# 変更ファイル確認
CHANGED_FILES=$(git status --porcelain 2>/dev/null | wc -l | xargs)
if [ "$CHANGED_FILES" -gt 0 ]; then
    echo "📝 Changed Files: $CHANGED_FILES files"
    git status --short | head -5
    if [ "$CHANGED_FILES" -gt 5 ]; then
        echo "... and $((CHANGED_FILES - 5)) more"
    fi
else
    echo "✅ Working Directory: Clean"
fi
echo ""

# ビルド状況確認
echo "🏗️ Build Status:"
if [ -f "build.log" ]; then
    LAST_BUILD=$(tail -1 build.log 2>/dev/null | grep -E "(BUILD SUCCEEDED|BUILD FAILED)" || echo "Unknown")
    BUILD_TIME=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" build.log 2>/dev/null || echo "Unknown")
    echo "Last Build: $LAST_BUILD ($BUILD_TIME)"
else
    echo "No build log found"
fi

# 最新の建置錯誤があれば表示
if [ -d "workoutbuilderror" ] && [ -n "$(ls -A workoutbuilderror 2>/dev/null)" ]; then
    LATEST_ERROR=$(ls -t workoutbuilderror/*.txt 2>/dev/null | head -1)
    if [ -n "$LATEST_ERROR" ]; then
        ERROR_TIME=$(basename "$LATEST_ERROR" | sed 's/Build Delax100DaysWorkout_\(.*\)\.txt/\1/' | sed 's/T/ /')
        echo "⚠️ Latest Build Error: $ERROR_TIME"
    fi
fi
echo ""

# プロジェクト統計
echo "📊 Project Stats:"
SWIFT_FILES=$(find Delax100DaysWorkout -name "*.swift" 2>/dev/null | wc -l | xargs)
TOTAL_LINES=$(find Delax100DaysWorkout -name "*.swift" -exec cat {} \; 2>/dev/null | wc -l | xargs)
echo "Swift Files: $SWIFT_FILES"
echo "Total Lines of Code: $TOTAL_LINES"

# モデル数
MODELS=$(find Delax100DaysWorkout/Models -name "*.swift" 2>/dev/null | wc -l | xargs)
echo "Data Models: $MODELS"

# TODO/FIXMEカウント
TODOS=$(grep -r "TODO\|FIXME" Delax100DaysWorkout --include="*.swift" 2>/dev/null | wc -l | xargs)
echo "TODO/FIXME items: $TODOS"
echo ""

# 進捗ファイル確認
echo "📋 Progress Files:"
if [ -f "PROGRESS_UNIFIED.md" ]; then
    LAST_UPDATED=$(grep "Last Updated:" PROGRESS_UNIFIED.md | tail -1 | sed 's/.*Last Updated: //')
    echo "✅ PROGRESS_UNIFIED.md (Updated: $LAST_UPDATED)"
else
    echo "❌ PROGRESS_UNIFIED.md not found"
fi

if [ -f "PROGRESS.md" ]; then
    echo "📄 PROGRESS.md (Legacy)"
fi

if [ -f "IMPLEMENTATION_HISTORY.md" ]; then
    echo "📚 IMPLEMENTATION_HISTORY.md (Archive)"
fi
echo ""

# --fullオプションが指定された場合の詳細表示
if [ "$1" = "--full" ]; then
    echo "🔍 Detailed Analysis (--full mode):"
    echo "================================="
    
    # 最近のコミット履歴
    echo ""
    echo "📝 Recent Commits (last 5):"
    git log --oneline -5 2>/dev/null || echo "No commit history"
    
    # 大きなファイルトップ5
    echo ""
    echo "📏 Largest Swift Files (top 5):"
    find Delax100DaysWorkout -name "*.swift" -exec wc -l {} \; 2>/dev/null | sort -rn | head -5 | while read lines file; do
        filename=$(basename "$file")
        echo "  $lines lines - $filename"
    done
    
    # Components構造
    echo ""
    echo "🧩 Components Structure:"
    if [ -d "Delax100DaysWorkout/Components" ]; then
        find Delax100DaysWorkout/Components -type d -depth 1 2>/dev/null | while read dir; do
            count=$(find "$dir" -name "*.swift" 2>/dev/null | wc -l | xargs)
            echo "  $(basename "$dir"): $count files"
        done
    else
        echo "  No Components directory"
    fi
fi

echo ""
echo "🎯 Next Steps:"
echo "1. Check PROGRESS_UNIFIED.md for current session focus"
echo "2. Review 'NEXT SESSION PRIORITY' section"
echo "3. Use '--full' flag for detailed analysis"
echo ""
echo "💡 Quick Commands:"
echo "  ./build.sh          - Run build"
echo "  ./quick-status.sh --full  - Detailed status" 
echo "================================================="