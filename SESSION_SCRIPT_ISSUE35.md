# SESSION_SCRIPT_ISSUE35.md
## 🔧 統一エラーハンドリング戦略: 成熟アーキテクチャの完成

### 🎯 セッション目標
Issue #35を一気通貫で完全実装し、シミュレーションビルドが通るまで確認

---

## 📋 **一気通貫実行プロンプト**

```
Claude、Issue #35 (🔧 統一エラーハンドリング戦略実装) を一気通貫で実装してください。

## 🎯 実行内容
1. **Issue #35の要求内容確認**: GitHub issueの詳細を正確に理解
2. **統一エラーハンドリング実装**: 
   - 既存AppError.swiftとErrorHandler.swiftの拡張
   - 統一エラー表示コンポーネント作成
   - SwiftData操作エラーの統一処理
   - ネットワークエラーの統一処理
   - ユーザー向けエラーメッセージの多言語対応
3. **既存コードの統合**: 75箇所のprint()文を適切なLogger呼び出しに変換
4. **実装確認**: シミュレーションビルドが通ることを確認
5. **Issue #35をクローズ**: GitHub上でクローズ
6. **PROGRESS.md更新**: 完了状況を反映
7. **次セッションスクリプト作成**: SESSION_SCRIPT_ISSUE60.md作成

## 🎯 戦略的位置づけ
**基盤イネーブラー**: 既存成熟アーキテクチャの唯一の欠落部分を補完し、全ての将来機能が一貫したエラーUXを持てるようにする

## ✅ 受入条件
- [ ] 統一エラー表示コンポーネント (BaseCard統合)
- [ ] SwiftDataエラー統一処理
- [ ] ネットワークエラー統一処理
- [ ] print()文→Logger変換 (75箇所)
- [ ] 多言語エラーメッセージ
- [ ] ハプティックフィードバック統合
- [ ] BUILD SUCCEEDED確認

## 📌 制約
- 1セッション1イシューの原則を守る
- Issue #35のみに集中し、他のイシューには手を出さない
- 既存のLogger.swift、AppError.swift、ErrorHandler.swiftを最大限活用
- BaseCard、HapticManager、SemanticColorの既存UIシステムと統合

完了したら「Issue #35完全実装完了、基盤システム完成、次セッション準備完了」とお知らせください。
```

---

## 📋 **実装チェックリスト** (参考)

### Phase 1: 要求分析・既存評価
- [ ] Issue #35詳細確認
- [ ] 既存エラーハンドリング調査 (AppError.swift, ErrorHandler.swift)
- [ ] Logger.swift活用方針確認
- [ ] print()文所在調査 (75箇所)

### Phase 2: 統一エラーシステム実装
- [ ] 統一エラー表示コンポーネント
- [ ] SwiftDataエラー処理統一
- [ ] ネットワークエラー処理統一
- [ ] print()→Logger移行

### Phase 3: UX統合
- [ ] BaseCard統合エラーUI
- [ ] ハプティックフィードバック
- [ ] 多言語エラーメッセージ

### Phase 4: 品質確認
- [ ] BUILD SUCCEEDED確認
- [ ] エラーハンドリング動作確認
- [ ] ログ出力確認

### Phase 5: 完了処理
- [ ] Issue #35クローズ
- [ ] PROGRESS.md更新  
- [ ] SESSION_SCRIPT_ISSUE60.md作成

---

## 🔗 **関連ファイル** (参考)
- Utils/AppError.swift
- Utils/ErrorHandler.swift
- Utils/Logger.swift
- Components/Cards/BaseCard.swift
- Utils/Haptics/HapticManager.swift

---

*Created: 2025-08-13*  
*Updated: 2025-08-13 (Post Issue #47 Completion)*  
*Target: Issue #35 Complete Implementation*  
*Strategic Position: 基盤イネーブラー - Priority #2*  
*Previous: Issue #47 (✅ Completed - Drag & Drop Functionality)*  
*Next: SESSION_SCRIPT_ISSUE60.md (Priority #3 - 汎用CRUD Engine)*