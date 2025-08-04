# 実装計画: delax-shared-packages統合

## 実装フェーズ

### Phase 1: 基盤準備とパッケージ統合
**目標**: 共有パッケージの依存関係を追加し、基本的な統合を行う
**期間**: 1セッション
**リスク**: 低

#### 1.1 Package.swiftの作成・設定
- [ ] Xcode プロジェクトにPackage.swiftファイルを作成
- [ ] DelaxSwiftUIComponents依存関係を追加
- [ ] ビルド確認とエラー修正

#### 1.2 基本インポートテスト
- [ ] DelaxSwiftUIComponentsのインポート確認
- [ ] 既存機能への影響がないことを確認
- [ ] ビルドとテスト実行

#### 1.3 検証ポイント
- ✅ プロジェクトが正常にビルドされる
- ✅ 既存機能が全て動作する
- ✅ パッケージが正しく解決される

### Phase 2: バグレポート機能の統合
**目標**: BugReportManagerをDelaxBugReportManagerに統合
**期間**: 1セッション
**リスク**: 中

#### 2.1 DelaxBugReportManager設定
- [ ] Application起動時の設定追加
- [ ] EnvironmentConfigとの統合
- [ ] GitHub認証情報の設定

#### 2.2 既存コードの段階的移行
- [ ] BugReportManagerの呼び出し箇所を特定
- [ ] typealias を使用した段階的移行
- [ ] メソッド呼び出しの互換性確認

#### 2.3 ShakeDetector統合
- [ ] 既存ShakeDetectorをDelaxShakeDetectorに置き換え
- [ ] MainView.swiftでの統合
- [ ] シェイクジェスチャーの動作確認

#### 2.4 検証ポイント
- ✅ バグレポート機能が正常動作する
- ✅ シェイクジェスチャーが機能する
- ✅ GitHub Issue作成が成功する
- ✅ スクリーンショット機能が動作する

### Phase 3: iOS Auto-Fix機能の統合
**目標**: 自動ビルド修正システムを導入
**期間**: 1セッション
**リスク**: 中〜高

#### 3.1 設定ファイル作成
- [ ] auto-fix-config.ymlファイル作成
- [ ] プロジェクト固有の設定値を記入
- [ ] Claude API設定の確認

#### 3.2 スクリプト統合
- [ ] 共有パッケージからスクリプトをコピー
- [ ] 実行権限の設定
- [ ] ローカルでの動作テスト

#### 3.3 GitHub Actions統合
- [ ] .github/workflows/auto-build-fix.yml作成
- [ ] GitHub Secrets設定 (ANTHROPIC_API_KEY)
- [ ] ワークフローの動作テスト

#### 3.4 検証ポイント
- ✅ 自動ビルド修正が機能する
- ✅ Watch modeが正常動作する
- ✅ GitHub Actionsが正常実行される
- ✅ エラー自動修正が成功する

## 技術実装詳細

### 1. Package.swift実装
```swift
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Delax100DaysWorkout",
    platforms: [.iOS(.v17)],
    dependencies: [
        .package(
            url: "https://github.com/DELAxGithub/delax-shared-packages.git",
            branch: "main"
        )
    ],
    targets: [
        .executableTarget(
            name: "Delax100DaysWorkout",
            dependencies: [
                .product(name: "DelaxSwiftUIComponents", 
                        package: "delax-shared-packages")
            ]
        )
    ]
)
```

### 2. Application統合コード
```swift
// Delax100DaysWorkoutApp.swift
import DelaxSwiftUIComponents

@main
struct Delax100DaysWorkoutApp: App {
    init() {
        // DelaxBugReportManager設定
        DelaxBugReportManager.shared.configure(
            gitHubToken: EnvironmentConfig.githubToken,
            gitHubOwner: EnvironmentConfig.githubOwner,
            gitHubRepo: EnvironmentConfig.githubRepo
        )
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
```

### 3. MainView統合
```swift
// MainView.swift
import DelaxSwiftUIComponents

struct MainView: View {
    @StateObject private var bugReportManager = DelaxBugReportManager.shared
    
    var body: some View {
        // 既存のビュー内容
        ContentView()
            .onReceive(DelaxShakeDetector.shared.shakePublisher) { _ in
                bugReportManager.showBugReportView()
            }
            .sheet(isPresented: $bugReportManager.isReportingBug) {
                DelaxBugReportView()
            }
    }
}
```

### 4. 移行時の互換性保持
```swift
// Services/BugReportManager.swift (移行期間中)
import DelaxSwiftUIComponents

// 既存コードとの互換性を保つ
typealias BugReportManager = DelaxBugReportManager
typealias BugReport = DelaxBugReport
typealias BugCategory = DelaxBugCategory
// ... その他必要な型エイリアス
```

## リスク管理

### 高リスク項目と対策

#### 1. パッケージ依存関係の競合
**リスク**: 既存の依存関係との競合
**対策**: 
- 段階的導入で影響範囲を限定
- 競合発生時の即座のロールバック手順を準備
- テスト環境での事前検証

#### 2. ビルド設定の変更
**リスク**: Xcodeプロジェクト設定の破損
**対策**:
- プロジェクトファイルのバックアップ作成
- Git commitでの段階的保存
- 自動的なプロジェクト復旧スクリプト準備

#### 3. Auto-Fix機能の誤動作
**リスク**: 意図しないコード変更
**対策**:
- Dry-runモードでの事前テスト
- Git-basedバックアップシステム
- 手動承認フローの導入

### 中リスク項目と対策

#### 1. API互換性の問題
**リスク**: メソッドシグネチャの違い
**対策**: Adapter パターンでの互換性維持

#### 2. 設定管理の複雑化
**リスク**: 設定の重複・競合
**対策**: 設定の統一化と検証システム

## テスト計画

### 単体テスト
- [ ] DelaxBugReportManager の設定テスト
- [ ] ShakeDetector の動作テスト
- [ ] GitHub API統合テスト

### 統合テスト
- [ ] アプリ全体の動作テスト
- [ ] バグレポートフローのE2E テスト
- [ ] Auto-Fix機能の統合テスト

### 回帰テスト
- [ ] 既存機能の全動作確認
- [ ] パフォーマンス影響の測定
- [ ] メモリリーク検出

## ロールバック手順

### 緊急時対応
1. **即座のロールバック**: `git revert` による変更の取り消し
2. **パッケージ除去**: Package.swift からの依存関係削除
3. **設定復旧**: 既存の設定ファイルへの復旧
4. **動作確認**: ロールバック後の全機能テスト

### 段階的ロールバック
1. **Phase 3ロールバック**: Auto-Fix機能のみ無効化
2. **Phase 2ロールバック**: バグレポート機能を既存版に戻す
3. **Phase 1ロールバック**: パッケージ依存関係を完全削除

## 完了基準

### 機能面
- ✅ 全既存機能が正常動作
- ✅ 新しいバグレポート機能が動作
- ✅ Auto-Fix機能が期待通りに動作
- ✅ パフォーマンス劣化なし

### 品質面
- ✅ ビルドエラー・警告なし
- ✅ メモリリークなし
- ✅ クラッシュなし
- ✅ 適切なエラーハンドリング

### 文書面
- ✅ 変更点の文書化完了
- ✅ 設定手順の明文化
- ✅ トラブルシューティングガイド作成

この実装計画により、安全かつ効率的にdelax-shared-packagesをdelax100daysworkoutに統合できます。