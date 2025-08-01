#!/bin/bash

# 通知システムスクリプト
# GitHub Actions や手動実行から呼び出し可能

set -e

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 使用方法を表示
show_help() {
    echo -e "${BLUE}📢 Delax100DaysWorkout 通知システム${NC}"
    echo ""
    echo "使用方法:"
    echo "  ./scripts/notify.sh <通知タイプ> [オプション]"
    echo ""
    echo "通知タイプ:"
    echo "  pr-created <PR番号>     - PR作成通知"
    echo "  build-success <PR番号>  - ビルド成功通知"
    echo "  build-failure <PR番号>  - ビルド失敗通知"
    echo "  ready-to-merge <PR番号> - マージ準備完了通知"
    echo "  issue-fixed <Issue番号> - Issue修正完了通知"
    echo ""
    echo "例:"
    echo "  ./scripts/notify.sh pr-created 30"
    echo "  ./scripts/notify.sh build-success 30"
    echo ""
}

# macOS通知を送信
send_macos_notification() {
    local title="$1"
    local message="$2"
    local sound="${3:-Blow}"
    
    if command -v osascript >/dev/null 2>&1; then
        osascript -e "display notification \"$message\" with title \"$title\" sound name \"$sound\""
        echo -e "${GREEN}📱 macOS通知を送信しました${NC}"
    else
        echo -e "${YELLOW}⚠️  macOS通知機能が利用できません${NC}"
    fi
}

# Slack通知（環境変数 SLACK_WEBHOOK_URL が設定されている場合）
send_slack_notification() {
    local message="$1"
    local emoji="${2:-:bell:}"
    
    if [ -n "$SLACK_WEBHOOK_URL" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$emoji $message\"}" \
            "$SLACK_WEBHOOK_URL" >/dev/null 2>&1
        echo -e "${GREEN}📤 Slack通知を送信しました${NC}"
    else
        echo -e "${YELLOW}ℹ️  Slack通知をスキップ（SLACK_WEBHOOK_URL未設定）${NC}"
    fi
}

# メール通知（環境変数 NOTIFICATION_EMAIL が設定されている場合）
send_email_notification() {
    local subject="$1"
    local body="$2"
    
    if [ -n "$NOTIFICATION_EMAIL" ] && command -v mail >/dev/null 2>&1; then
        echo "$body" | mail -s "$subject" "$NOTIFICATION_EMAIL"
        echo -e "${GREEN}📧 メール通知を送信しました${NC}"
    else
        echo -e "${YELLOW}ℹ️  メール通知をスキップ（設定未完了）${NC}"
    fi
}

# PR情報を取得
get_pr_info() {
    local pr_number="$1"
    gh pr view "$pr_number" --json title,url,author,headRefName 2>/dev/null || {
        echo -e "${RED}❌ PR #${pr_number} の情報取得に失敗${NC}"
        return 1
    }
}

# Issue情報を取得
get_issue_info() {
    local issue_number="$1"
    gh issue view "$issue_number" --json title,url,author 2>/dev/null || {
        echo -e "${RED}❌ Issue #${issue_number} の情報取得に失敗${NC}"
        return 1
    }
}

# 引数チェック
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

NOTIFICATION_TYPE="$1"
TARGET_NUMBER="$2"

echo -e "${BLUE}📢 通知システムを開始: $NOTIFICATION_TYPE${NC}"

case "$NOTIFICATION_TYPE" in
    "pr-created")
        if [ -z "$TARGET_NUMBER" ]; then
            echo -e "${RED}❌ PR番号が必要です${NC}"
            exit 1
        fi
        
        PR_INFO=$(get_pr_info "$TARGET_NUMBER")
        if [ $? -eq 0 ]; then
            PR_TITLE=$(echo "$PR_INFO" | jq -r '.title')
            PR_URL=$(echo "$PR_INFO" | jq -r '.url')
            PR_AUTHOR=$(echo "$PR_INFO" | jq -r '.author.login')
            
            TITLE="🆕 新しいPRが作成されました"
            MESSAGE="PR #${TARGET_NUMBER}: ${PR_TITLE} by ${PR_AUTHOR}"
            
            echo -e "${GREEN}✅ PR作成通知${NC}"
            echo "  📝 $PR_TITLE"
            echo "  👤 作成者: $PR_AUTHOR"
            echo "  🔗 $PR_URL"
            
            send_macos_notification "$TITLE" "$MESSAGE" "Glass"
            send_slack_notification "🆕 新しいPR作成: [#${TARGET_NUMBER} ${PR_TITLE}]($PR_URL) by @${PR_AUTHOR}" ":git:"
            send_email_notification "$TITLE" "PR詳細:\nタイトル: ${PR_TITLE}\n作成者: ${PR_AUTHOR}\nURL: ${PR_URL}"
        fi
        ;;
        
    "build-success")
        if [ -z "$TARGET_NUMBER" ]; then
            echo -e "${RED}❌ PR番号が必要です${NC}"
            exit 1
        fi
        
        PR_INFO=$(get_pr_info "$TARGET_NUMBER")
        if [ $? -eq 0 ]; then
            PR_TITLE=$(echo "$PR_INFO" | jq -r '.title')
            PR_URL=$(echo "$PR_INFO" | jq -r '.url')
            
            TITLE="✅ ビルド成功"
            MESSAGE="PR #${TARGET_NUMBER} のiOSビルドが成功しました"
            
            echo -e "${GREEN}✅ ビルド成功通知${NC}"
            echo "  📝 $PR_TITLE"
            echo "  🔗 $PR_URL"
            
            send_macos_notification "$TITLE" "$MESSAGE" "Hero"
            send_slack_notification "✅ ビルド成功: [PR #${TARGET_NUMBER}]($PR_URL) - レビュー・マージの準備ができました！" ":white_check_mark:"
            send_email_notification "$TITLE" "PR #${TARGET_NUMBER} のビルドが成功しました。\n\n詳細: ${PR_URL}"
        fi
        ;;
        
    "build-failure")
        if [ -z "$TARGET_NUMBER" ]; then
            echo -e "${RED}❌ PR番号が必要です${NC}"
            exit 1
        fi
        
        PR_INFO=$(get_pr_info "$TARGET_NUMBER")
        if [ $? -eq 0 ]; then
            PR_TITLE=$(echo "$PR_INFO" | jq -r '.title')
            PR_URL=$(echo "$PR_INFO" | jq -r '.url')
            
            TITLE="❌ ビルド失敗"
            MESSAGE="PR #${TARGET_NUMBER} のiOSビルドが失敗しました"
            
            echo -e "${RED}❌ ビルド失敗通知${NC}"
            echo "  📝 $PR_TITLE"
            echo "  🔗 $PR_URL"
            
            send_macos_notification "$TITLE" "$MESSAGE" "Basso"
            send_slack_notification "❌ ビルド失敗: [PR #${TARGET_NUMBER}]($PR_URL) - 修正が必要です" ":x:"
            send_email_notification "$TITLE" "PR #${TARGET_NUMBER} のビルドが失敗しました。\n\n確認してください: ${PR_URL}"
        fi
        ;;
        
    "ready-to-merge")
        if [ -z "$TARGET_NUMBER" ]; then
            echo -e "${RED}❌ PR番号が必要です${NC}"
            exit 1
        fi
        
        PR_INFO=$(get_pr_info "$TARGET_NUMBER")
        if [ $? -eq 0 ]; then
            PR_TITLE=$(echo "$PR_INFO" | jq -r '.title')
            PR_URL=$(echo "$PR_INFO" | jq -r '.url')
            
            TITLE="🚀 マージ準備完了"
            MESSAGE="PR #${TARGET_NUMBER} はマージの準備ができています"
            
            echo -e "${GREEN}🚀 マージ準備完了通知${NC}"
            echo "  📝 $PR_TITLE"
            echo "  🔗 $PR_URL"
            echo "  💡 コマンド: ./scripts/sync-pr.sh $TARGET_NUMBER"
            
            send_macos_notification "$TITLE" "$MESSAGE" "Submarine"
            send_slack_notification "🚀 マージ準備完了: [PR #${TARGET_NUMBER}]($PR_URL)\n\`./scripts/sync-pr.sh ${TARGET_NUMBER}\` でローカル同期できます" ":rocket:"
            send_email_notification "$TITLE" "PR #${TARGET_NUMBER} がマージ準備完了です。\n\nローカル同期コマンド:\n./scripts/sync-pr.sh ${TARGET_NUMBER}\n\nPR URL: ${PR_URL}"
        fi
        ;;
        
    "issue-fixed")
        if [ -z "$TARGET_NUMBER" ]; then
            echo -e "${RED}❌ Issue番号が必要です${NC}"
            exit 1
        fi
        
        ISSUE_INFO=$(get_issue_info "$TARGET_NUMBER")
        if [ $? -eq 0 ]; then
            ISSUE_TITLE=$(echo "$ISSUE_INFO" | jq -r '.title')
            ISSUE_URL=$(echo "$ISSUE_INFO" | jq -r '.url')
            
            TITLE="🛠️ Issue修正完了"
            MESSAGE="Issue #${TARGET_NUMBER} の修正PRが作成されました"
            
            echo -e "${GREEN}🛠️ Issue修正完了通知${NC}"
            echo "  📝 $ISSUE_TITLE"
            echo "  🔗 $ISSUE_URL"
            
            send_macos_notification "$TITLE" "$MESSAGE" "Ping"
            send_slack_notification "🛠️ Issue修正完了: [#${TARGET_NUMBER} ${ISSUE_TITLE}]($ISSUE_URL) - PRが作成されました" ":wrench:"
            send_email_notification "$TITLE" "Issue #${TARGET_NUMBER} の修正が完了し、PRが作成されました。\n\n詳細: ${ISSUE_URL}"
        fi
        ;;
        
    *)
        echo -e "${RED}❌ 不明な通知タイプ: $NOTIFICATION_TYPE${NC}"
        show_help
        exit 1
        ;;
esac

echo -e "${BLUE}📢 通知送信完了${NC}"