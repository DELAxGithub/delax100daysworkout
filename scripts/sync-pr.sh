#!/bin/bash

# PR同期・ビルド・マージスクリプト
# 使用方法: ./scripts/sync-pr.sh <PR番号>

set -e

# カラー出力用
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ヘルプ表示
show_help() {
    echo -e "${BLUE}📱 Delax100DaysWorkout PR同期スクリプト${NC}"
    echo ""
    echo "使用方法:"
    echo "  ./scripts/sync-pr.sh <PR番号>"
    echo ""
    echo "例:"
    echo "  ./scripts/sync-pr.sh 30"
    echo ""
    echo "このスクリプトは以下を実行します:"
    echo "  1. 指定PRのブランチをローカルに同期"
    echo "  2. Xcodeでビルド＆テスト"
    echo "  3. 成功時にマージオプション表示"
    echo ""
}

# 引数チェック
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

PR_NUMBER=$1

echo -e "${BLUE}🚀 PR #${PR_NUMBER} の同期とビルドを開始します...${NC}"

# PRの情報を取得
echo -e "${YELLOW}📋 PR情報を取得中...${NC}"
PR_INFO=$(gh pr view $PR_NUMBER --json headRefName,headRepository,title,url,author 2>/dev/null) || {
    echo -e "${RED}❌ エラー: PR #${PR_NUMBER} が見つかりません${NC}"
    echo "GitHub CLIがインストールされ、認証されていることを確認してください"
    exit 1
}

BRANCH_NAME=$(echo $PR_INFO | jq -r '.headRefName')
PR_TITLE=$(echo $PR_INFO | jq -r '.title')
PR_URL=$(echo $PR_INFO | jq -r '.url')
PR_AUTHOR=$(echo $PR_INFO | jq -r '.author.login')

echo -e "${GREEN}✅ PR情報取得完了${NC}"
echo "  📝 タイトル: $PR_TITLE"
echo "  🌿 ブランチ: $BRANCH_NAME"
echo "  👤 作成者: $PR_AUTHOR"
echo "  🔗 URL: $PR_URL"
echo ""

# 現在のブランチを保存
CURRENT_BRANCH=$(git branch --show-current)
echo -e "${YELLOW}💾 現在のブランチ '${CURRENT_BRANCH}' を保存${NC}"

# PRブランチをフェッチしてチェックアウト
echo -e "${YELLOW}🔄 PR ブランチをフェッチ中...${NC}"
git fetch origin pull/$PR_NUMBER/head:pr-$PR_NUMBER 2>/dev/null || {
    echo -e "${YELLOW}ℹ️  新しいブランチとして作成します${NC}"
}

git checkout pr-$PR_NUMBER 2>/dev/null || {
    echo -e "${YELLOW}📥 PR ブランチをチェックアウト中...${NC}"
    gh pr checkout $PR_NUMBER
}

echo -e "${GREEN}✅ ブランチ同期完了${NC}"

# ビルド実行
echo ""
echo -e "${BLUE}🔨 Xcodeビルドを実行中...${NC}"
echo "  📱 対象: iOS Simulator (iPhone 16 Pro)"
echo "  ⚙️  設定: Debug"

BUILD_LOG_FILE="error/Build_PR${PR_NUMBER}_$(date +%Y-%m-%dT%H-%M-%S).txt"
mkdir -p error

if ./build.sh > "$BUILD_LOG_FILE" 2>&1; then
    echo -e "${GREEN}✅ ビルド成功！${NC}"
    BUILD_SUCCESS=true
    
    # 簡単な動作確認（シミュレーターが利用可能な場合）
    echo ""
    echo -e "${YELLOW}🧪 シミュレーターでの動作確認（オプション）${NC}"
    echo "シミュレーターで動作確認しますか？ (y/N)"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}📱 シミュレーターを起動中...${NC}"
        open -a Simulator
        echo "シミュレーターでアプリをテストしてください"
        echo "完了したら Enter キーを押してください"
        read
    fi
    
else
    echo -e "${RED}❌ ビルド失敗${NC}"
    echo "  📄 ログファイル: $BUILD_LOG_FILE"
    echo ""
    echo -e "${YELLOW}📋 エラー詳細（最後の20行）:${NC}"
    tail -20 "$BUILD_LOG_FILE"
    BUILD_SUCCESS=false
fi

echo ""

# 結果に応じた次のアクション
if [ "$BUILD_SUCCESS" = true ]; then
    echo -e "${GREEN}🎉 PR #${PR_NUMBER} のビルドとテストが完了しました！${NC}"
    echo ""
    echo -e "${BLUE}📋 次のアクション:${NC}"
    echo "  1. コードの最終確認"
    echo "  2. マージの実行"
    echo "  3. 元のブランチに戻る"
    echo ""
    
    echo "このPRをマージしますか？ (y/N)"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}🔄 PRをマージ中...${NC}"
        
        # マージタイプを選択
        echo "マージタイプを選択してください:"
        echo "  1. Merge commit (推奨)"
        echo "  2. Squash and merge"
        echo "  3. Rebase and merge"
        echo -n "選択 (1-3): "
        read -n 1 MERGE_TYPE
        echo
        
        case $MERGE_TYPE in
            1)
                gh pr merge $PR_NUMBER --merge
                ;;
            2)
                gh pr merge $PR_NUMBER --squash
                ;;
            3)
                gh pr merge $PR_NUMBER --rebase
                ;;
            *)
                echo -e "${YELLOW}⏭️  マージをスキップします${NC}"
                ;;
        esac
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ マージ完了！${NC}"
            
            # mainブランチを更新
            git checkout main
            git pull origin main
            
            # PRブランチを削除
            git branch -D pr-$PR_NUMBER 2>/dev/null || true
            
            echo -e "${GREEN}🧹 ローカルブランチを削除しました${NC}"
        else
            echo -e "${RED}❌ マージに失敗しました${NC}"
        fi
    else
        echo -e "${YELLOW}⏭️  マージをスキップしました${NC}"
    fi
    
else
    echo -e "${RED}💥 ビルドエラーにより処理を中断します${NC}"
    echo ""
    echo -e "${BLUE}📋 推奨アクション:${NC}"
    echo "  1. エラーログを確認: $BUILD_LOG_FILE"
    echo "  2. 必要に応じてPRにコメント"
    echo "  3. PRの修正を依頼"
fi

# 元のブランチに戻る
echo ""
echo -e "${YELLOW}🔄 元のブランチ '${CURRENT_BRANCH}' に戻ります${NC}"
git checkout "$CURRENT_BRANCH"

echo ""
echo -e "${BLUE}📊 処理完了サマリー:${NC}"
echo "  📋 PR: #${PR_NUMBER} - $PR_TITLE"
echo "  🔨 ビルド: $([ "$BUILD_SUCCESS" = true ] && echo "✅ 成功" || echo "❌ 失敗")"
echo "  📂 ログ: $BUILD_LOG_FILE"
echo "  🌿 現在のブランチ: $(git branch --show-current)"

if [ "$BUILD_SUCCESS" = true ]; then
    echo ""
    echo -e "${GREEN}🎉 お疲れさまでした！${NC}"
else
    echo ""
    echo -e "${YELLOW}🔧 ビルドエラーの修正が必要です${NC}"
fi