# 🚀 クイックリファレンス (Quick Reference Guide)

## 📋 **頻繁に使用するコマンド**

### **進捗管理**
```bash
# 現状を素早く把握 (30秒)
./scripts/quick-status.sh

# 詳細分析
./scripts/quick-status.sh --full

# セッション開始
./scripts/progress-tracker.sh session-start

# セッション終了  
./scripts/progress-tracker.sh session-end

# 進捗更新
./scripts/progress-tracker.sh update
```

### **ビルド・テスト**
```bash
# プロジェクトビルド
./build.sh

# ビルドログ確認
tail -20 build.log

# エラー確認
ls -la workoutbuilderror/
```

### **Git操作**
```bash
# 現在の状況
git status

# 最近のコミット
git log --oneline -5

# 変更ファイル確認
git diff --name-only

# クイックコミット
git add . && git commit -m "🎯 [概要]" && git push
```

---

## 📊 **重要ファイル・ディレクトリ**

### **進捗管理ファイル**
- `PROGRESS_UNIFIED.md` - **メイン進捗ファイル** (常に最新)
- `PROGRESS.md` - レガシー進捗ファイル (参考用)  
- `IMPLEMENTATION_HISTORY.md` - 実装履歴アーカイブ
- `SESSION_TEMPLATE.md` - セッション記録テンプレート

### **プロジェクト構造**
```
Delax100DaysWorkout/
├── Components/          # 共通UIコンポーネント
├── Features/            # 機能別ビュー
├── Models/              # データモデル (19+モデル)
├── Services/            # ビジネスロジック・サービス
├── Utils/               # ユーティリティ・ヘルパー
└── Assets.xcassets/     # アセット・リソース

scripts/                 # 自動化スクリプト
docs/                    # ドキュメント
workoutbuilderror/       # ビルドエラーログ
```

### **重要なシステムファイル**
- `build.sh` - ビルドスクリプト
- `build.log` - ビルドログ
- `auto-fix-config.yml` - 自動修正設定

---

## 🎯 **よくある作業パターン**

### **新しいイシューに着手する時**
1. `./scripts/quick-status.sh` で現状確認
2. `PROGRESS_UNIFIED.md` で次のイシューを確認  
3. `./scripts/progress-tracker.sh session-start` でセッション開始
4. `SESSION_TEMPLATE.md` をコピーして作業記録作成

### **ビルドエラーが発生した時**
1. `./build.sh` でビルド実行
2. `tail -20 build.log` でエラー確認
3. `workoutbuilderror/` の最新ファイル確認
4. エラー修正後、再度 `./build.sh`

### **セッション完了時**
1. 全ての変更をコミット・プッシュ
2. `PROGRESS_UNIFIED.md` の実績セクション更新
3. `./scripts/progress-tracker.sh session-end` で記録
4. 次セッションの推奨イシューを決定

---

## 🏆 **完了済み重要システム**

### **✅ 利用可能なCore基盤**
- **Universal Edit Sheet** - 1行で全モデル編集可能
- **汎用CRUD Engine** - 型安全な19+モデルCRUD操作
- **企業級CI/CD** - 10 workflows・99%エラー予防
- **統一エラーハンドリング** - AppError + ErrorHandler
- **汎用アナリティクス** - 80%コード再利用フレームワーク
- **HealthKit統合** - 自動同期・データ取得

### **🎨 UIコンポーネントシステム**
- **BaseCard統一システム** - 943個のスタイル重複除去
- **統一ヘッダー・プルダウンUI** - Apple Reminders風デザイン
- **アクセシビリティ完全対応** - VoiceOver・44ptタッチターゲット

---

## 🚧 **現在のHIGH PRIORITY課題**

### **推奨: 機能不調修正** (60-90分)
- 動作しない機能修正・API連携問題・データ同期不具合修正
- **基盤完了**: ローカリゼーション問題解決・設定画面安定化

### **代替選択肢**
- **Issue #58**: 学術レベル相関分析システム (90-120分)
- **Issue #77**: Universal Edit Sheet Production統合 (75分)  
- **Issue #69**: データ投入完全自動化 (90分)

---

## 🔍 **トラブルシューティング**

### **ビルドエラー**
```bash
# ビルドログ確認
cat build.log | tail -20

# 最新エラーファイル確認
ls -la workoutbuilderror/ | head -5

# クリーンビルド
rm -rf ~/Library/Developer/Xcode/DerivedData/Delax100DaysWorkout*
./build.sh
```

### **Git問題**
```bash
# 現在の状況確認
git status
git log --oneline -3

# 未追跡ファイル確認
git status --porcelain | grep "??"

# 変更の差分確認
git diff --stat
```

### **進捗記録問題**
```bash
# バックアップから復元
ls -la .progress_backup/
cp .progress_backup/progress_backup_YYYYMMDD_HHMMSS.md PROGRESS_UNIFIED.md

# 進捗ファイル修復
./scripts/progress-tracker.sh update
```

---

## 💡 **効率化のTips**

### **セッション前** (3分で完了)
1. `./scripts/quick-status.sh` - 現状把握
2. `PROGRESS_UNIFIED.md` - 次のタスク確認
3. `./scripts/progress-tracker.sh session-start` - セッション開始

### **開発中**
- 小さな機能完了毎にコミット
- 30分毎に進捗を `SESSION_TEMPLATE.md` に記録
- ビルドエラーは即座に修正

### **セッション後** (5分で完了)
1. 全変更をコミット・プッシュ
2. `PROGRESS_UNIFIED.md` 更新
3. `./scripts/progress-tracker.sh session-end`
4. 次回のイシューを決定

---

## 📱 **アプリ固有の重要情報**

### **SwiftDataモデル** (19+モデル)
- `WorkoutRecord` - トレーニング記録のメイン
- `DailyTask` - 日次タスク管理
- `WeeklyTemplate` - 週間スケジュール
- `FTPHistory` - FTPテスト履歴
- その他詳細モデル多数

### **主要機能エリア**
- **Home** - トレーニング管理・今日のタスク
- **WPR** - アナリティクス・科学的指標分析
- **History** - 履歴管理・検索・フィルタ
- **Settings** - 設定・HealthKit統合

### **技術スタック**
- **SwiftUI** + **SwiftData** (iOS 18.5+)
- **HealthKit** 統合
- **企業レベルMVVM** + **Protocol-based設計**
- **汎用コンポーネントシステム**

---

*Quick Reference Version: 1.0*  
*Last Updated: 2025-08-22*