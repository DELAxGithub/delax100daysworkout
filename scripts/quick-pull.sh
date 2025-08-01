#!/bin/bash

# 手動プル用の簡単コマンド
# ワンコマンドでプル→通知→Xcodeビルド推奨まで実行

set -e

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 設定
MAIN_BRANCH="main"
REMOTE_NAME="origin"

echo -e "${BLUE}🚀 Quick Pull - 手動プル＆通知システム${NC}"
echo ""

# 現在のディレクトリがGitリポジトリかチェック
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo -e "${RED}❌ Not a git repository${NC}"
    exit 1
fi

# 現在のブランチがmainかチェック
current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
if [ "$current_branch" != "$MAIN_BRANCH" ]; then
    echo -e "${YELLOW}⚠️ Current branch is '$current_branch', switching to '$MAIN_BRANCH'...${NC}"
    git checkout "$MAIN_BRANCH" 2>/dev/null || {
        echo -e "${RED}❌ Failed to switch to main branch${NC}"
        exit 1
    }
fi

# プル前の状態を記録
echo -e "${BLUE}📊 Checking current status...${NC}"
current_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
short_current=$(echo "$current_commit" | cut -c1-8)

# 作業ディレクトリの状態をチェック
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo -e "${YELLOW}⚠️ Working directory has uncommitted changes${NC}"
    echo -e "${BLUE}💡 Please commit or stash your changes before pulling${NC}"
    echo ""
    echo -e "${PURPLE}Uncommitted files:${NC}"
    git status --porcelain
    echo ""
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🛑 Pull cancelled${NC}"
        exit 0
    fi
fi

# Fetch to check for updates
echo -e "${BLUE}🔍 Fetching latest changes...${NC}"
if ! git fetch "$REMOTE_NAME" "$MAIN_BRANCH" 2>/dev/null; then
    echo -e "${RED}❌ Failed to fetch from remote${NC}"
    exit 1
fi

# リモートの最新コミットを取得
remote_commit=$(git rev-parse "$REMOTE_NAME/$MAIN_BRANCH" 2>/dev/null || echo "unknown")
short_remote=$(echo "$remote_commit" | cut -c1-8)

# 更新があるかチェック
if [ "$current_commit" = "$remote_commit" ]; then
    echo -e "${GREEN}✅ Already up to date${NC}"
    echo -e "${PURPLE}Current commit: $short_current${NC}"
    
    # 通知は送信（テスト用）
    echo -e "${BLUE}📢 Sending notification anyway...${NC}"
    if command -v ./scripts/notify.sh >/dev/null 2>&1; then
        ./scripts/notify.sh xcode-recommended
    fi
    exit 0
fi

# 変更の概要を表示
echo -e "${YELLOW}📥 New changes detected!${NC}"
echo -e "${PURPLE}Current:  $short_current${NC}"
echo -e "${PURPLE}Remote:   $short_remote${NC}"
echo ""

# コミット履歴を表示（最大5件）
echo -e "${BLUE}📋 Recent commits to pull:${NC}"
git log --oneline "${current_commit}..${remote_commit}" -n 5 2>/dev/null || echo "Unable to show commit history"
echo ""

# プル実行の確認
read -p "Pull these changes? (Y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
    echo -e "${YELLOW}🛑 Pull cancelled${NC}"
    exit 0
fi

# プル実行
echo -e "${BLUE}🔄 Pulling changes...${NC}"
if git pull "$REMOTE_NAME" "$MAIN_BRANCH" 2>/dev/null; then
    echo -e "${GREEN}✅ Successfully pulled latest changes!${NC}"
    
    new_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    short_new=$(echo "$new_commit" | cut -c1-8)
    
    echo -e "${PURPLE}Updated: $short_current → $short_new${NC}"
    echo ""
    
    # 成功通知を送信
    echo -e "${BLUE}📢 Sending notifications...${NC}"
    if command -v ./scripts/notify.sh >/dev/null 2>&1; then
        # プル完了通知
        ./scripts/notify.sh merge-pulled "$new_commit"
        echo -e "${GREEN}📱 Pull completion notification sent${NC}"
        
        # 少し待ってからXcodeビルド推奨通知（notify.sh内で自動実行されるが念のため）
        sleep 1
        echo -e "${GREEN}🔨 Xcode build recommendation sent${NC}"
    else
        echo -e "${YELLOW}⚠️ Notification script not found, skipping notifications${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Quick pull completed successfully!${NC}"
    echo -e "${BLUE}💡 Next steps:${NC}"
    echo -e "${PURPLE}   1. Open Xcode${NC}"
    echo -e "${PURPLE}   2. Build the project (⌘+B)${NC}"
    echo -e "${PURPLE}   3. Test on simulator or device${NC}"
    echo ""
    
else
    echo -e "${RED}❌ Failed to pull changes${NC}"
    echo ""
    echo -e "${BLUE}💡 Possible solutions:${NC}"
    echo -e "${PURPLE}   1. Check for merge conflicts${NC}"
    echo -e "${PURPLE}   2. Ensure you have the latest changes committed${NC}"
    echo -e "${PURPLE}   3. Try: git status${NC}"
    exit 1
fi