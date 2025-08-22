#!/bin/bash

# 📊 Progress Tracker - 進捗自動更新スクリプト
# Usage: ./scripts/progress-tracker.sh [update|session-start|session-end]

PROGRESS_FILE="PROGRESS_UNIFIED.md"
BACKUP_DIR=".progress_backup"

# バックアップディレクトリ作成
mkdir -p "$BACKUP_DIR"

# 現在の日時取得
CURRENT_DATE=$(date '+%Y-%m-%d')
CURRENT_DATETIME=$(date '+%Y-%m-%d %H:%M')

# バックアップ作成関数
create_backup() {
    if [ -f "$PROGRESS_FILE" ]; then
        cp "$PROGRESS_FILE" "$BACKUP_DIR/progress_backup_$(date +%Y%m%d_%H%M%S).md"
        echo "✅ Backup created: $BACKUP_DIR/progress_backup_$(date +%Y%m%d_%H%M%S).md"
    fi
}

# セッション開始時の処理
session_start() {
    echo "🚀 Session Start - Progress Tracker"
    echo "===================================="
    
    create_backup
    
    # 現在の統計情報取得
    SWIFT_FILES=$(find Delax100DaysWorkout -name "*.swift" 2>/dev/null | wc -l | xargs)
    TOTAL_LINES=$(find Delax100DaysWorkout -name "*.swift" -exec cat {} \; 2>/dev/null | wc -l | xargs)
    CHANGED_FILES=$(git status --porcelain 2>/dev/null | wc -l | xargs)
    LAST_COMMIT=$(git log -1 --pretty=format:'%h - %s' 2>/dev/null || echo 'No commits')
    
    echo "📊 Session Start Stats:"
    echo "  Swift Files: $SWIFT_FILES"
    echo "  Lines of Code: $TOTAL_LINES" 
    echo "  Changed Files: $CHANGED_FILES"
    echo "  Last Commit: $LAST_COMMIT"
    echo ""
    
    # セッション開始を記録
    if [ -f "$PROGRESS_FILE" ]; then
        # Last Updatedを更新
        sed -i.bak "s/Last Updated: .*/Last Updated: $CURRENT_DATE/" "$PROGRESS_FILE"
        echo "✅ Progress file updated with session start time"
    fi
    
    echo "🎯 Ready to start development session!"
}

# セッション終了時の処理
session_end() {
    echo "🏁 Session End - Progress Update"
    echo "================================="
    
    create_backup
    
    # Git情報収集
    COMMITS_SINCE_START=$(git log --since="2 hours ago" --oneline 2>/dev/null | wc -l | xargs)
    CHANGED_FILES=$(git status --porcelain 2>/dev/null | wc -l | xargs)
    RECENT_COMMITS=$(git log --since="2 hours ago" --pretty=format:'- %s' 2>/dev/null)
    
    echo "📊 Session Summary:"
    echo "  Commits Made: $COMMITS_SINCE_START"
    echo "  Files Changed: $CHANGED_FILES"
    
    if [ -n "$RECENT_COMMITS" ]; then
        echo "  Recent Commits:"
        echo "$RECENT_COMMITS" | head -3
    fi
    
    # ビルド状況確認
    if [ -f "build.log" ]; then
        LAST_BUILD_STATUS=$(tail -1 build.log 2>/dev/null | grep -E "(BUILD SUCCEEDED|BUILD FAILED)" || echo "Unknown")
        echo "  Build Status: $LAST_BUILD_STATUS"
    fi
    
    echo ""
    
    # 進捗ファイル更新
    if [ -f "$PROGRESS_FILE" ]; then
        # Last Updatedを更新
        sed -i.bak "s/Last Updated: .*/Last Updated: $CURRENT_DATE/" "$PROGRESS_FILE"
        
        # セッション実績をコメントとして追加 (手動で移動してもらう)
        echo "" >> session_summary_temp.md
        echo "## 🔄 Session Summary ($CURRENT_DATETIME)" >> session_summary_temp.md
        echo "- Commits: $COMMITS_SINCE_START" >> session_summary_temp.md
        echo "- Changed Files: $CHANGED_FILES" >> session_summary_temp.md
        if [ -n "$RECENT_COMMITS" ]; then
            echo "- Key Changes:" >> session_summary_temp.md
            echo "$RECENT_COMMITS" | head -3 >> session_summary_temp.md
        fi
        echo "" >> session_summary_temp.md
        
        echo "✅ Session summary created in: session_summary_temp.md"
        echo "💡 You can manually add this to $PROGRESS_FILE if needed"
    fi
    
    echo "🎯 Session completed successfully!"
}

# 基本的な更新処理
update_progress() {
    echo "🔄 Updating Progress Information"
    echo "==============================="
    
    create_backup
    
    if [ -f "$PROGRESS_FILE" ]; then
        # Last Updatedを更新
        sed -i.bak "s/Last Updated: .*/Last Updated: $CURRENT_DATE/" "$PROGRESS_FILE"
        echo "✅ Progress file date updated"
    else
        echo "❌ Progress file not found: $PROGRESS_FILE"
        exit 1
    fi
    
    # プロジェクト統計表示
    echo ""
    echo "📊 Current Project Stats:"
    ./scripts/quick-status.sh
}

# メイン処理
case "${1:-update}" in
    "session-start")
        session_start
        ;;
    "session-end")
        session_end
        ;;
    "update")
        update_progress
        ;;
    *)
        echo "Usage: $0 [update|session-start|session-end]"
        echo ""
        echo "Commands:"
        echo "  update        - Update progress file with current date"
        echo "  session-start - Initialize session and record start stats"
        echo "  session-end   - Finalize session and create summary"
        exit 1
        ;;
esac