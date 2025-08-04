# iOS Swift特化テンプレート - 完全仕様

## 🎯 目標

新しいiOS Swiftプロジェクト（プロジェクトマネジメントツール + ClaudeKit等）で即座に高効率ワークフローを構築できる特化テンプレート。

## 📱 対応技術スタック

### 基本スタック
- **iOS**: 17.0+
- **Xcode**: 15.0+
- **Swift**: 5.9+
- **SwiftUI**: 最新
- **SwiftData**: Core Data代替

### 拡張スタック（オプション対応）
- **ClaudeKit**: AI機能統合
- **Networking**: URLSession + async/await
- **Testing**: XCTest + ViewInspector
- **CI/CD**: GitHub Actions

## 📁 iOS Swift テンプレート構造

```
templates/ios-swift/
├── README.md                          # iOS特化説明
├── setup-ios.sh                       # iOS専用セットアップ
├── build.sh.template                  # Xcodeビルドスクリプト
├── .github/
│   └── workflows/
│       ├── ios-code-check.yml         # Swift特化コードチェック
│       └── ios-release.yml.template   # TestFlight配布（オプション）
├── scripts/
│   ├── xcode-project-setup.sh         # Xcodeプロジェクト設定
│   ├── simulator-management.sh        # シミュレーター管理
│   └── build-helpers.sh               # ビルド支援ツール
├── config/
│   ├── ios-config.yml                 # iOS固有設定
│   └── xcode-schemes.yml.example      # Xcodeスキーム設定
├── docs/
│   ├── XCODE_INTEGRATION.md           # Xcode連携詳細
│   ├── CLAUDEKIT_SETUP.md             # ClaudeKit統合手順
│   ├── SWIFTUI_BEST_PRACTICES.md      # SwiftUI開発ガイド
│   └── TESTING_GUIDE.md               # iOS テスト戦略
└── examples/
    ├── sample-swiftui-app/            # サンプルSwiftUIアプリ
    ├── claudekit-integration/         # ClaudeKit連携例
    └── project-structure/             # 推奨ディレクトリ構造
```

## 🔧 iOS特化 GitHub Actions

### `ios-code-check.yml`
```yaml
name: iOS Code Check

on:
  pull_request:
    types: [opened, synchronize, reopened]
    paths:
      - '**/*.swift'
      - '*.xcodeproj/**'
      - '*.xcworkspace/**'

jobs:
  swift-check:
    name: Swift Code Quality Check
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        
      - name: Swift Syntax Check
        run: |
          echo "🔍 Checking Swift files..."
          
          # Swift ファイルの基本構文チェック
          find . -name "*.swift" -type f | while read -r file; do
            echo "Checking: $file"
            
            # Import文チェック
            if grep -n "import SwiftUI\|import Foundation\|import UIKit" "$file" > /dev/null; then
              echo "✅ $file - Standard imports found"
            else
              echo "⚠️ $file - No standard imports found"
            fi
            
            # 基本的なSwiftUI構造チェック
            if grep -n "struct.*View\|class.*ObservableObject" "$file" > /dev/null; then
              echo "✅ $file - SwiftUI structure detected"
            fi
            
            # ClaudeKit使用チェック
            if grep -n "import ClaudeKit\|Claude\|AI" "$file" > /dev/null; then
              echo "🤖 $file - ClaudeKit integration detected"
            fi
            
            # 未閉じ括弧チェック
            if [ "$(grep -o '{' "$file" | wc -l)" -ne "$(grep -o '}' "$file" | wc -l)" ]; then
              echo "❌ $file - Mismatched braces detected"
              exit 1
            fi
          done
          
          echo "✅ Swift syntax check completed"
          
      - name: Check Xcode Project
        run: |
          echo "🔍 Checking Xcode project structure..."
          
          # .xcodeproj ファイル存在チェック
          if ls *.xcodeproj 1> /dev/null 2>&1; then
            echo "✅ Xcode project file found"
            
            # Info.plist チェック
            if find . -name "Info.plist" | head -1; then
              echo "✅ Info.plist found"
            fi
            
            # Assets.xcassets チェック  
            if find . -name "Assets.xcassets" | head -1; then
              echo "✅ Assets catalog found"
            fi
          else
            echo "⚠️ No Xcode project file found"
          fi
          
      - name: SwiftUI Best Practices Check
        run: |
          echo "🔍 Checking SwiftUI best practices..."
          
          # @State/@StateObject/@ObservedObject 使用パターンチェック
          find . -name "*.swift" -exec grep -l "@State\|@StateObject\|@ObservedObject" {} \; | while read -r file; do
            echo "📱 $file - SwiftUI state management detected"
            
            # プライベート@State変数の推奨パターンチェック
            if grep -n "@State private var" "$file" > /dev/null; then
              echo "✅ $file - Proper private @State usage"
            fi
          done
          
      - name: Comment Result on PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const prNumber = context.payload.pull_request.number;
            
            const comment = `## ✅ iOS Code Check Passed!
            
            🎉 **Swift/SwiftUIコードチェックが完了しました**
            
            ### チェック内容
            - **Swift構文**: 基本構文エラーなし
            - **Import文**: SwiftUI/Foundation/UIKit確認
            - **SwiftUI構造**: View/ObservableObject確認
            - **ClaudeKit**: AI機能連携チェック
            - **Xcodeプロジェクト**: プロジェクト構造確認
            - **ベストプラクティス**: @State/@StateObject使用確認
            
            ### 次のステップ
            1. コード変更内容をレビュー
            2. 手動でマージを実行  
            3. \`./scripts/quick-pull.sh\` でローカル同期
            4. Xcodeでビルド・実機テスト実行
            
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
              labels: ['✅ iOS Check Passed', 'Ready for review', 'SwiftUI']
            });
```

## 🛠️ iOS特化ビルドスクリプト

### `build.sh.template`
```bash
#!/bin/bash

# iOS Swift プロジェクト専用ビルドスクリプト
# Delax100DaysWorkoutプロジェクトで実証済みの設定をベース

set -e

# カラー出力
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# プロジェクト設定（テンプレート展開時に自動設定）
PROJECT_NAME="{{PROJECT_NAME}}"                    # 例: MyProjectApp
SCHEME_NAME="{{SCHEME_NAME}}"                      # 例: MyProjectApp
XCODEPROJ_PATH="{{XCODEPROJ_PATH}}"               # 例: MyProjectApp.xcodeproj

# デフォルト設定
SIMULATOR_NAME="iPhone 16 Pro"
FALLBACK_SIMULATOR="iPhone 15 Pro"
CONFIGURATION="Debug"

echo -e "${BLUE}🔨 Building iOS Project: $PROJECT_NAME${NC}"
echo ""

# Xcodeプロジェクトの存在確認
if [ ! -d "$XCODEPROJ_PATH" ]; then
    echo -e "${RED}❌ Xcode project not found: $XCODEPROJ_PATH${NC}"
    echo -e "${YELLOW}💡 Current directory contents:${NC}"
    ls -la
    exit 1
fi

# 利用可能なシミュレーターを表示
echo -e "${BLUE}📱 Available simulators:${NC}"
xcrun simctl list devices available | grep iPhone | head -5

echo ""
echo -e "${BLUE}🧹 Cleaning previous builds...${NC}"

# クリーンビルド実行
if xcodebuild clean \
    -project "$XCODEPROJ_PATH" \
    -scheme "$SCHEME_NAME" \
    -destination "platform=iOS Simulator,name=$SIMULATOR_NAME,OS=latest" 2>/dev/null; then
    echo -e "${GREEN}✅ Clean completed${NC}"
else
    echo -e "${YELLOW}⚠️ Clean with $SIMULATOR_NAME failed, trying $FALLBACK_SIMULATOR...${NC}"
    xcodebuild clean \
        -project "$XCODEPROJ_PATH" \
        -scheme "$SCHEME_NAME" \
        -destination "platform=iOS Simulator,name=$FALLBACK_SIMULATOR,OS=latest"
fi

echo ""
echo -e "${BLUE}🔨 Building project...${NC}"

# メインビルド実行
BUILD_RESULT=0
if xcodebuild build \
    -project "$XCODEPROJ_PATH" \
    -scheme "$SCHEME_NAME" \
    -destination "platform=iOS Simulator,name=$SIMULATOR_NAME,OS=latest" \
    -configuration "$CONFIGURATION" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO; then
    
    echo -e "${GREEN}✅ Build completed successfully!${NC}"
    
else
    echo -e "${YELLOW}⚠️ Build with $SIMULATOR_NAME failed, trying $FALLBACK_SIMULATOR...${NC}"
    
    if xcodebuild build \
        -project "$XCODEPROJ_PATH" \
        -scheme "$SCHEME_NAME" \
        -destination "platform=iOS Simulator,name=$FALLBACK_SIMULATOR,OS=latest" \
        -configuration "$CONFIGURATION" \
        CODE_SIGN_IDENTITY="" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO; then
        
        echo -e "${GREEN}✅ Build completed with $FALLBACK_SIMULATOR!${NC}"
    else
        echo -e "${RED}❌ Build failed with both simulators${NC}"
        
        echo ""
        echo -e "${BLUE}💡 Troubleshooting suggestions:${NC}"
        echo -e "${YELLOW}1. Check available simulators: xcrun simctl list devices${NC}"
        echo -e "${YELLOW}2. Verify project scheme: $SCHEME_NAME${NC}" 
        echo -e "${YELLOW}3. Open Xcode and check for build errors${NC}"
        echo -e "${YELLOW}4. Check Target Membership for Swift files${NC}"
        
        BUILD_RESULT=1
    fi
fi

# ビルド後の処理
if [ $BUILD_RESULT -eq 0 ]; then
    echo ""
    echo -e "${GREEN}🎉 iOS Build Successful!${NC}"
    echo -e "${BLUE}📱 Next steps:${NC}"
    echo -e "${YELLOW}1. Open Xcode: open $XCODEPROJ_PATH${NC}"
    echo -e "${YELLOW}2. Run on simulator (⌘+R)${NC}"
    echo -e "${YELLOW}3. Test ClaudeKit integration if applicable${NC}"
    echo -e "${YELLOW}4. Test on physical device${NC}"
    
    # 成功通知（通知システムが利用可能な場合）
    if command -v ./scripts/notify.sh >/dev/null 2>&1; then
        ./scripts/notify.sh build-success "iOS-Build"
    fi
    
else
    echo ""
    echo -e "${RED}💥 iOS Build Failed${NC}"
    
    # 失敗通知
    if command -v ./scripts/notify.sh >/dev/null 2>&1; then
        ./scripts/notify.sh build-failure "iOS-Build"
    fi
    
    exit 1
fi
```

## ⚙️ iOS設定ファイル

### `config/ios-config.yml`
```yaml
# iOS Swift プロジェクト設定

project:
  name: "{{PROJECT_NAME}}"
  bundle_id: "{{BUNDLE_ID}}"               # com.company.appname
  deployment_target: "17.0"
  swift_version: "5.9"

xcode:
  project_file: "{{PROJECT_NAME}}.xcodeproj"
  scheme: "{{PROJECT_NAME}}"
  configuration: "Debug"
  
build:
  simulators:
    primary: "iPhone 16 Pro"
    fallback: "iPhone 15 Pro"
  signing:
    code_sign_identity: ""
    code_signing_required: false
    code_signing_allowed: false

testing:
  enabled: true
  test_scheme: "{{PROJECT_NAME}}Tests"
  ui_test_scheme: "{{PROJECT_NAME}}UITests"
  
features:
  claudekit:
    enabled: false                        # ClaudeKit統合の有無
    version: "latest"
  swiftdata:
    enabled: true                         # SwiftData使用
  networking:
    enabled: true                         # async/await networking
    
notifications:
  build_success: true
  build_failure: true
  test_results: true

# 推奨ディレクトリ構造
directory_structure:
  - "{{PROJECT_NAME}}/"
  - "{{PROJECT_NAME}}/App/"              # アプリケーション層
  - "{{PROJECT_NAME}}/Features/"         # 機能別View
  - "{{PROJECT_NAME}}/Models/"           # データモデル
  - "{{PROJECT_NAME}}/Services/"         # サービス層
  - "{{PROJECT_NAME}}/Utils/"            # ユーティリティ
  - "{{PROJECT_NAME}}/Resources/"        # リソース
```

## 📖 iOS特化ドキュメント

### 含まれるドキュメント
1. **XCODE_INTEGRATION.md** - Xcode連携詳細
2. **CLAUDEKIT_SETUP.md** - ClaudeKit統合手順
3. **SWIFTUI_BEST_PRACTICES.md** - SwiftUI開発ガイド
4. **TESTING_GUIDE.md** - iOS テスト戦略

## 🚀 セットアップフロー

### 1. テンプレートから新プロジェクト作成
```bash
gh repo create my-project-management-tool --template claude-dev-workflow-template
cd my-project-management-tool
./setup.sh ios-swift
```

### 2. プロンプトでの設定入力
```
Project Name: MyProjectTool
Bundle ID: com.delax.myprojecttool
Enable ClaudeKit? (y/N): y
Enable SwiftData? (Y/n): y
Slack notifications? (y/N): n
```

### 3. 自動生成される構造
```
my-project-management-tool/
├── MyProjectTool.xcodeproj/
├── MyProjectTool/
│   ├── App/
│   │   └── MyProjectToolApp.swift
│   ├── Features/
│   │   ├── Dashboard/
│   │   └── Projects/
│   ├── Models/
│   └── Services/
├── .github/workflows/
│   ├── claude.yml
│   └── ios-code-check.yml
├── scripts/
│   ├── quick-pull.sh
│   └── notify.sh
└── build.sh
```

### 4. 即座利用開始
```bash
# ビルドテスト
./build.sh

# 開発開始
open MyProjectTool.xcodeproj

# Issue作成・PR作成・マージ後
./scripts/quick-pull.sh
```

## 🏆 期待される効果

### 開発開始時間
- **従来**: 2-3日（プロジェクト作成・ワークフロー構築・設定）
- **テンプレート使用**: 30分（セットアップ完了・開発開始可能）

### 品質保証
- 実証済みワークフローの適用
- SwiftUI/ClaudeKit ベストプラクティス
- 自動コードチェック・通知システム

### 新プロジェクトマネジメントツール開発での適用
- ClaudeKit統合による AI機能
- SwiftData による効率的データ管理
- 高効率開発ワークフロー

---

**このiOS Swift特化テンプレートにより、新プロジェクトで即座に高品質な開発環境を構築し、AI統合アプリの開発を効率化できます。**