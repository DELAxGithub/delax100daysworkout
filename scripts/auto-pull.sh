#!/bin/bash

# 自動プルシステム
# マージ検知とローカル同期の自動化

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
CHECK_INTERVAL=30  # 秒
LOG_FILE="logs/auto-pull.log"

# ログディレクトリ作成
mkdir -p logs

# ログ関数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" | tee -a "$LOG_FILE"
}

# 使用方法を表示
show_help() {
    echo -e "${BLUE}🔄 自動プルシステム${NC}"
    echo ""
    echo "使用方法:"
    echo "  ./scripts/auto-pull.sh [オプション]"
    echo ""
    echo "オプション:"
    echo "  start           - 監視を開始（バックグラウンド実行）"
    echo "  stop            - 監視を停止"
    echo "  status          - 監視状態を確認"
    echo "  once            - 一回だけチェック実行"
    echo "  --interval N    - チェック間隔を N 秒に設定（デフォルト: 30秒）"
    echo ""
    echo "例:"
    echo "  ./scripts/auto-pull.sh start"
    echo "  ./scripts/auto-pull.sh once"
    echo "  ./scripts/auto-pull.sh start --interval 60"
    echo ""
}

# 現在のコミットハッシュを取得
get_current_commit() {
    git rev-parse HEAD 2>/dev/null || echo "unknown"
}

# リモートの最新コミットハッシュを取得
get_remote_commit() {
    git ls-remote "$REMOTE_NAME" "$MAIN_BRANCH" 2>/dev/null | cut -f1 || echo "unknown"
}

# git pull を安全に実行
safe_pull() {
    echo -e "${BLUE}🔄 Checking for updates...${NC}"
    
    # リモート情報を更新
    if ! git fetch "$REMOTE_NAME" "$MAIN_BRANCH" 2>/dev/null; then
        echo -e "${RED}❌ Failed to fetch from remote${NC}"
        log "ERROR: Failed to fetch from remote"
        return 1
    fi
    
    local current_commit=$(get_current_commit)
    local remote_commit=$(git rev-parse "$REMOTE_NAME/$MAIN_BRANCH" 2>/dev/null || echo "unknown")
    
    if [ "$current_commit" = "$remote_commit" ]; then
        echo -e "${GREEN}✅ Already up to date${NC}"
        return 0
    fi
    
    echo -e "${YELLOW}📥 New changes detected, pulling...${NC}"
    log "INFO: New changes detected - Local: $current_commit, Remote: $remote_commit"
    
    # 作業ディレクトリの状態をチェック
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        echo -e "${RED}❌ Working directory has uncommitted changes${NC}"
        echo -e "${YELLOW}💡 Please commit or stash your changes before auto-pull${NC}"
        log "ERROR: Uncommitted changes detected"
        return 1
    fi
    
    # プルを実行
    if git pull "$REMOTE_NAME" "$MAIN_BRANCH" 2>/dev/null; then
        echo -e "${GREEN}✅ Successfully pulled latest changes${NC}"
        log "SUCCESS: Pulled changes from $current_commit to $(get_current_commit)"
        
        # 通知を送信
        if command -v ./scripts/notify.sh >/dev/null 2>&1; then
            ./scripts/notify.sh merge-pulled "$remote_commit"
        fi
        
        return 0
    else
        echo -e "${RED}❌ Failed to pull changes${NC}"
        log "ERROR: Failed to pull changes"
        return 1
    fi
}

# 一回だけチェック実行
check_once() {
    echo -e "${BLUE}🔍 Single check execution${NC}"
    log "INFO: Single check started"
    
    if safe_pull; then
        echo -e "${GREEN}🎉 Check completed successfully${NC}"
        log "INFO: Single check completed successfully"
    else
        echo -e "${RED}💥 Check failed${NC}"
        log "ERROR: Single check failed"
        exit 1
    fi
}

# 監視開始
start_monitoring() {
    local pidfile="logs/auto-pull.pid"
    
    # 既に実行中かチェック
    if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
        echo -e "${YELLOW}⚠️ Auto-pull is already running (PID: $(cat "$pidfile"))${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🚀 Starting auto-pull monitoring...${NC}"
    echo -e "${PURPLE}📊 Check interval: ${CHECK_INTERVAL} seconds${NC}"
    echo -e "${PURPLE}📂 Log file: $LOG_FILE${NC}"
    
    log "INFO: Auto-pull monitoring started with interval ${CHECK_INTERVAL}s"
    
    # バックグラウンドで監視開始
    {
        while true; do
            safe_pull || true  # エラーでも継続
            sleep "$CHECK_INTERVAL"
        done
    } &
    
    local monitor_pid=$!
    echo "$monitor_pid" > "$pidfile"
    
    echo -e "${GREEN}✅ Auto-pull started in background (PID: $monitor_pid)${NC}"
    echo -e "${PURPLE}💡 Stop with: ./scripts/auto-pull.sh stop${NC}"
}

# 監視停止
stop_monitoring() {
    local pidfile="logs/auto-pull.pid"
    
    if [ ! -f "$pidfile" ]; then
        echo -e "${YELLOW}⚠️ No auto-pull process found${NC}"
        return 0
    fi
    
    local pid=$(cat "$pidfile")
    
    if kill -0 "$pid" 2>/dev/null; then
        echo -e "${BLUE}🛑 Stopping auto-pull monitoring (PID: $pid)...${NC}"
        kill "$pid"
        rm -f "$pidfile"
        echo -e "${GREEN}✅ Auto-pull stopped${NC}"
        log "INFO: Auto-pull monitoring stopped"
    else
        echo -e "${YELLOW}⚠️ Process $pid not found, cleaning up pidfile${NC}"
        rm -f "$pidfile"
    fi
}

# 監視状態確認
check_status() {
    local pidfile="logs/auto-pull.pid"
    
    echo -e "${BLUE}📊 Auto-pull Status${NC}"
    echo ""
    
    if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2>/dev/null; then
        local pid=$(cat "$pidfile")
        echo -e "${GREEN}✅ Running (PID: $pid)${NC}"
        echo -e "${PURPLE}📂 Log file: $LOG_FILE${NC}"
        echo -e "${PURPLE}⏰ Check interval: ${CHECK_INTERVAL} seconds${NC}"
        
        # 最新ログを表示
        if [ -f "$LOG_FILE" ]; then
            echo ""
            echo -e "${BLUE}📋 Recent logs:${NC}"
            tail -5 "$LOG_FILE" 2>/dev/null || echo "No logs available"
        fi
    else
        echo -e "${YELLOW}⚠️ Not running${NC}"
        rm -f "$pidfile" 2>/dev/null
    fi
    
    echo ""
    echo -e "${BLUE}📍 Repository status:${NC}"
    echo -e "${PURPLE}Branch: $(git branch --show-current 2>/dev/null || echo 'unknown')${NC}"
    echo -e "${PURPLE}Local commit: $(get_current_commit | cut -c1-8)${NC}"
    echo -e "${PURPLE}Remote commit: $(get_remote_commit | cut -c1-8)${NC}"
}

# 引数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        start)
            COMMAND="start"
            shift
            ;;
        stop)
            COMMAND="stop"
            shift
            ;;
        status)
            COMMAND="status"
            shift
            ;;
        once)
            COMMAND="once"
            shift
            ;;
        --interval)
            CHECK_INTERVAL="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# デフォルトコマンド（引数なしの場合）
if [ -z "${COMMAND:-}" ]; then
    show_help
    exit 0
fi

# 現在のディレクトリがGitリポジトリかチェック
if ! git rev-parse --git-dir >/dev/null 2>&1; then
    echo -e "${RED}❌ Not a git repository${NC}"
    exit 1
fi

# 現在のブランチがmainかチェック
current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
if [ "$current_branch" != "$MAIN_BRANCH" ]; then
    echo -e "${YELLOW}⚠️ Current branch is '$current_branch', not '$MAIN_BRANCH'${NC}"
    echo -e "${BLUE}💡 Auto-pull works best on the main branch${NC}"
fi

# コマンド実行
case "$COMMAND" in
    start)
        start_monitoring
        ;;
    stop)
        stop_monitoring
        ;;
    status)
        check_status
        ;;
    once)
        check_once
        ;;
esac