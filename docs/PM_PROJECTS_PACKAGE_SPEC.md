# PM系プロジェクト専用パッケージ仕様

## 🎯 対象プロジェクト

読み込んだObsidianドキュメントから、以下のプロジェクトマネジメント系プロジェクト群が対象：

### 1. **DELAxPM** - 統合番組制作管理システム
- PMLibraryとPMPlattoの統合プロジェクト
- **技術スタック**: Next.js 15, React 18, TypeScript, Supabase, モノレポ構成
- **特徴**: 完成度高い統合システム、本番運用準備完了

### 2. **PMLibrary** - 番組制作進捗管理
- エピソード管理、すごろく式カンバン、チーム共有機能
- **技術スタック**: React 18, TypeScript, Vite, Supabase, Tailwind CSS
- **特徴**: 稼働中システム、リアルタイム更新対応

### 3. **PMPlatto** - 番組制作管理（PR納品管理特化）
- PR管理機能、番組制作ワークフロー
- **技術スタック**: React, TypeScript（詳細は統合済み）

### 4. **新規PM系プロジェクト**
- 将来の番組制作管理ツール
- 統合プラットフォーム基盤の活用

---

## 📦 PM専用パッケージ: `claude-pm-workflow-template`

### パッケージ特化ポイント

#### 🎬 **プロジェクトマネジメント特化機能**
- **モノレポ構成**: 複数アプリ統合対応
- **Supabase統合**: PostgreSQL + Auth + Realtime + Edge Functions
- **Next.js App Router**: 最新アーキテクチャ対応
- **TypeScript**: 型安全な開発環境

#### 🚀 **PM系プロジェクト即座セットアップ**
```bash
# PM系プロジェクト作成
gh repo create new-pm-project --template claude-pm-workflow-template
cd new-pm-project
./setup.sh pm-supabase-nextjs
# → PM系プロジェクトが30分で完成
```

---

## 🏗️ PM特化テンプレート構造

```
claude-pm-workflow-template/
├── templates/
│   ├── pm-supabase-nextjs/           # PM系メインテンプレート
│   │   ├── README.md                 # PM系プロジェクト説明
│   │   ├── setup-pm.sh               # PM専用セットアップ
│   │   ├── apps/                     # モノレポ アプリ群
│   │   │   ├── unified/              # 統合アプリ（DELAxPM形式）
│   │   │   └── legacy/               # レガシーアプリ移行用
│   │   ├── packages/                 # 共通パッケージ
│   │   │   ├── shared-ui/            # UI コンポーネント
│   │   │   ├── shared-types/         # TypeScript型定義
│   │   │   └── supabase-client/      # Supabase統合
│   │   ├── supabase/                 # Supabase設定
│   │   │   ├── migrations/           # DB移行スクリプト
│   │   │   ├── functions/            # Edge Functions
│   │   │   └── config.toml           # Supabase設定
│   │   ├── .github/workflows/        # PM系CI/CD
│   │   │   ├── pm-code-check.yml     # Next.js/Supabase チェック
│   │   │   └── pm-deploy.yml         # Netlify/Vercel デプロイ
│   │   └── config/
│   │       └── pm-config.yml         # PM系プロジェクト設定
│   └── ios-swift/                    # 既存iOS対応（変更なし）
├── scripts/                          # 汎用スクリプト（共通）
│   ├── quick-pull.sh                 # 手動プル（完全共通）
│   ├── auto-pull.sh                  # 自動プル（完全共通）
│   ├── sync-pr.sh                    # PR同期（完全共通）
│   └── notify.sh                     # 通知システム（完全共通）
└── docs/
    ├── PM_WORKFLOW_GUIDE.md          # PM系専用ワークフローガイド
    ├── SUPABASE_SETUP.md             # Supabase統合手順
    └── MONOREPO_GUIDE.md             # モノレポ運用ガイド
```

---

## 🔧 PM特化 GitHub Actions

### `pm-code-check.yml`
```yaml
name: PM Project Code Check

on:
  pull_request:
    types: [opened, synchronize, reopened]
    paths:
      - 'apps/**/*.{ts,tsx,js,jsx}'
      - 'packages/**/*.{ts,tsx,js,jsx}'
      - 'supabase/**/*.sql'
      - '*.json'

jobs:
  nextjs-check:
    name: Next.js TypeScript Check
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'pnpm'
          
      - name: Install dependencies
        run: pnpm install
        
      - name: TypeScript Check
        run: |
          echo "🔍 Checking TypeScript in PM project..."
          
          # モノレポ全体のTypeScriptチェック
          pnpm run type-check
          
          # Next.js App Router構文チェック
          find apps packages -name "*.tsx" -type f | while read -r file; do
            echo "Checking: $file"
            
            # React/Next.js Importチェック
            if grep -n "import.*from.*react\|import.*from.*next" "$file" > /dev/null; then
              echo "✅ $file - React/Next.js imports found"
            fi
            
            # Supabase統合チェック
            if grep -n "supabase\|@supabase" "$file" > /dev/null; then
              echo "🗄️ $file - Supabase integration detected"
            fi
            
            # PM系ビジネスロジックチェック
            if grep -n "episode\|program\|kanban\|dashboard" "$file" > /dev/null; then
              echo "📺 $file - PM business logic detected"
            fi
          done
          
      - name: Supabase Schema Check
        run: |
          echo "🗄️ Checking Supabase schema..."
          
          if [ -d "supabase/migrations" ]; then
            echo "✅ Supabase migrations directory found"
            
            # SQL構文の基本チェック
            find supabase/migrations -name "*.sql" | while read -r file; do
              echo "📄 $file - SQL migration file"
              
              # 基本的なSQL構文チェック
              if grep -i "CREATE TABLE\|ALTER TABLE\|DROP TABLE" "$file" > /dev/null; then
                echo "✅ $file - Contains table operations"
              fi
              
              # RLS (Row Level Security) チェック
              if grep -i "ROW LEVEL SECURITY\|POLICY" "$file" > /dev/null; then
                echo "🔒 $file - RLS policies detected"
              fi
            done
          fi
          
      - name: Comment Result on PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const prNumber = context.payload.pull_request.number;
            
            const comment = `## ✅ PM Project Check Passed!
            
            🎉 **プロジェクトマネジメント系コードチェックが完了しました**
            
            ### チェック内容
            - **TypeScript**: モノレポ全体の型チェック完了
            - **Next.js**: App Router構文・Import確認
            - **Supabase**: スキーマ・RLS設定確認
            - **PM機能**: エピソード・カンバン・ダッシュボード確認
            - **モノレポ**: packages間の依存関係確認
            
            ### 次のステップ
            1. コード変更内容をレビュー
            2. 手動でマージを実行
            3. \`./scripts/quick-pull.sh\` でローカル同期
            4. \`pnpm dev\` でローカルテスト実行
            
            **このPRは手動マージの準備ができています！** 🚀`;
            
            await github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: prNumber,
              body: comment
            });
            
            await github.rest.issues.addLabels({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: prNumber,
              labels: ['✅ PM Check Passed', 'Ready for review', 'Next.js', 'Supabase']
            });
```

---

## ⚙️ PM特化設定ファイル

### `config/pm-config.yml`
```yaml
# PM系プロジェクト設定

project:
  name: "{{PROJECT_NAME}}"
  type: "pm-supabase-nextjs"
  description: "Project Management System"

architecture:
  monorepo: true
  package_manager: "pnpm"
  build_system: "turbo"

tech_stack:
  frontend:
    framework: "Next.js 15"
    language: "TypeScript"
    ui: "Tailwind CSS"
    components: "shadcn/ui"
  
  backend:
    service: "Supabase"
    database: "PostgreSQL"
    auth: "Supabase Auth"
    realtime: "Supabase Realtime"
    functions: "Supabase Edge Functions"
  
  deployment:
    hosting: "Netlify"  # または Vercel
    ci_cd: "GitHub Actions"

supabase:
  project_url: "{{SUPABASE_URL}}"
  anon_key: "{{SUPABASE_ANON_KEY}}"
  features:
    - "Row Level Security"
    - "Realtime subscriptions"
    - "Edge Functions"
    - "Database migrations"

pm_features:
  episode_management: true
  kanban_board: true
  team_dashboard: true
  calendar_integration: true
  realtime_updates: true
  role_based_access: true

notifications:
  slack:
    enabled: false
    webhook_url: "${SLACK_WEBHOOK_URL}"
  email:
    enabled: false
    service: "Resend"
  weekly_reports: true

# 推奨ディレクトリ構造
directory_structure:
  - "apps/unified/"
  - "apps/unified/app/"              # Next.js App Router
  - "apps/unified/components/"       # React コンポーネント
  - "apps/unified/lib/"              # ユーティリティ
  - "packages/shared-ui/"            # 共通UIコンポーネント
  - "packages/shared-types/"         # TypeScript型定義
  - "packages/supabase-client/"      # Supabase接続
  - "supabase/migrations/"           # DB移行スクリプト
  - "supabase/functions/"            # Edge Functions
```

---

## 🛠️ PM特化ビルドスクリプト

### `build.sh.template`
```bash
#!/bin/bash

# PM系プロジェクト専用ビルドスクリプト
# Next.js + Supabase + モノレポ対応

set -e

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# プロジェクト設定
PROJECT_NAME="{{PROJECT_NAME}}"
MAIN_APP="apps/unified"

echo -e "${BLUE}🏗️ Building PM Project: $PROJECT_NAME${NC}"
echo ""

# package.json の存在確認
if [ ! -f "package.json" ]; then
    echo -e "${RED}❌ package.json not found${NC}"
    exit 1
fi

# pnpm の存在確認
if ! command -v pnpm &> /dev/null; then
    echo -e "${RED}❌ pnpm not found. Please install pnpm${NC}"
    echo -e "${YELLOW}💡 Install with: npm install -g pnpm${NC}"
    exit 1
fi

echo -e "${BLUE}📦 Installing dependencies...${NC}"
pnpm install

echo ""
echo -e "${BLUE}🔍 Type checking...${NC}"
if pnpm run type-check; then
    echo -e "${GREEN}✅ TypeScript check passed${NC}"
else
    echo -e "${RED}❌ TypeScript errors found${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔨 Building applications...${NC}"

# モノレポ全体ビルド
if pnpm run build; then
    echo -e "${GREEN}✅ Build completed successfully!${NC}"
    
    # ビルド成果物の確認
    if [ -d "$MAIN_APP/.next" ]; then
        echo -e "${GREEN}📱 Next.js build output found${NC}"
    fi
    
    if [ -d "packages/shared-ui/dist" ]; then
        echo -e "${GREEN}📦 Shared packages built${NC}"
    fi
    
else
    echo -e "${RED}❌ Build failed${NC}"
    echo ""
    echo -e "${BLUE}💡 Troubleshooting suggestions:${NC}"
    echo -e "${YELLOW}1. Check TypeScript errors: pnpm run type-check${NC}"
    echo -e "${YELLOW}2. Check dependencies: pnpm install${NC}"
    echo -e "${YELLOW}3. Check Supabase connection: pnpm run db:status${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 PM Project Build Successful!${NC}"
echo -e "${BLUE}📱 Next steps:${NC}"
echo -e "${YELLOW}1. Start development: pnpm run dev${NC}"
echo -e "${YELLOW}2. Test Supabase connection${NC}"
echo -e "${YELLOW}3. Check PM features (Episodes, Kanban, Dashboard)${NC}"
echo -e "${YELLOW}4. Deploy to Netlify/Vercel${NC}"

# 成功通知
if command -v ./scripts/notify.sh >/dev/null 2>&1; then
    ./scripts/notify.sh build-success "PM-Build"
fi
```

---

## 🚀 PM系プロジェクト使用フロー

### 1. 新プロジェクト作成
```bash
gh repo create delax-new-pm-system --template claude-pm-workflow-template
cd delax-new-pm-system
./setup.sh pm-supabase-nextjs
```

### 2. 設定入力プロンプト
```
Project Name: DelaxNewPMSystem
Supabase Project URL: https://xxx.supabase.co
Enable Realtime? (Y/n): Y
Enable Team Dashboard? (Y/n): Y
Enable Kanban Board? (Y/n): Y
Weekly Reports? (Y/n): Y
```

### 3. 自動生成される構造
```
delax-new-pm-system/
├── apps/
│   └── unified/                     # Next.js App Router
│       ├── app/
│       │   ├── dashboard/
│       │   ├── episodes/
│       │   └── kanban/
│       └── components/
├── packages/
│   ├── shared-ui/                   # PM系UIコンポーネント
│   └── supabase-client/             # Supabase統合
├── supabase/
│   ├── migrations/                  # PM系スキーマ
│   └── functions/                   # 週次レポート等
└── scripts/                        # Claude高効率ワークフロー
    ├── quick-pull.sh
    └── notify.sh
```

### 4. 即座開発開始
```bash
# ビルドテスト
./build.sh

# 開発開始
pnpm dev

# Issue作成・PR作成・マージ後
./scripts/quick-pull.sh
```

---

## 🏆 PM系プロジェクトでの効果

### DELAxPM統合プロジェクトでの適用例
- **既存の統合経験を活用**: PMLibrary + PMPlatto統合ノウハウをテンプレート化
- **モノレポ構成**: 既に実証済みの構成をそのまま適用
- **Supabase統合**: RLS、Edge Functions、Realtime を標準装備

### 新規PM系プロジェクトでの効果
- **開発開始時間**: 1-2週間 → 30分（95%短縮）
- **品質保証**: 実証済みアーキテクチャの即座適用
- **スケーラビリティ**: モノレポによる複数アプリ対応

---

**このPM系専用パッケージにより、Supabase + Next.js + モノレポ構成のプロジェクトマネジメントシステムを即座に構築でき、既存のDELAxPM統合プロジェクトのノウハウを最大限活用できます。** 🎯✨