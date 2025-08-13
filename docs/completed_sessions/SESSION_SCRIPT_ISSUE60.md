# SESSION_SCRIPT_ISSUE60.md
## 🔧 汎用CRUD Engine実装: 開発速度乗数効果の実現

### 🎯 セッション目標
Issue #60を一気通貫で完全実装し、シミュレーションビルドが通るまで確認

---

## 📋 **一気通貫実行プロンプト**

```
Claude、Issue #60 (🔧 汎用CRUD Engine Framework実装) を一気通貫で実装してください。

## 🎯 実行内容
1. **Issue #60の要求内容確認**: GitHub issueの詳細を正確に理解
2. **汎用CRUD Engine実装**: 
   - Issue #46で実証されたパターンの汎用化
   - 型安全なCRUD操作インターフェース
   - SwiftData統合基盤エンジン
   - バリデーション・エラーハンドリング統合
   - BaseCard統一UI自動生成
3. **既存コードの統合**: 個別CRUD実装の統一化
4. **実装確認**: シミュレーションビルドが通ることを確認
5. **Issue #60をクローズ**: GitHub上でクローズ
6. **PROGRESS.md更新**: 完了状況を反映
7. **次セッションスクリプト作成**: SESSION_SCRIPT_ISSUE56.md作成

## 🎯 戦略的位置づけ
**開発速度乗数効果**: Issue #46で実証されたCRUDパターンを汎用化し、全てのデータモデルで再利用可能にする

## ✅ 受入条件
- [ ] 型安全汎用CRUD Engine
- [ ] SwiftData統合基盤
- [ ] 自動UI生成システム
- [ ] バリデーション統合
- [ ] エラーハンドリング統合 (Issue #35成果活用)
- [ ] 既存CRUD実装の統一化
- [ ] BUILD SUCCEEDED確認

## 📌 制約
- 1セッション1イシューの原則を守る
- Issue #60のみに集中し、他のイシューには手を出さない
- Issue #46・#35の成果を最大限活用
- 既存の個別CRUD実装を破壊せず統一化

完了したら「Issue #60完全実装完了、CRUD Engine基盤完成、次セッション準備完了」とお知らせください。
```

---

## 📋 **実装チェックリスト** (参考)

### Phase 1: 要求分析・既存評価
- [ ] Issue #60詳細確認
- [ ] Issue #46実装パターン分析
- [ ] 既存CRUD実装調査
- [ ] 汎用化要件定義

### Phase 2: 汎用CRUD Engine実装
- [ ] 型安全CRUDインターフェース
- [ ] SwiftData統合基盤
- [ ] 自動UI生成システム
- [ ] バリデーション統合

### Phase 3: 既存統合
- [ ] 個別CRUD実装の統一化
- [ ] BaseCard統一UI適用
- [ ] エラーハンドリング統合

### Phase 4: 品質確認
- [ ] BUILD SUCCEEDED確認
- [ ] CRUD操作動作確認
- [ ] 既存機能回帰確認

### Phase 5: 完了処理
- [ ] Issue #60クローズ
- [ ] PROGRESS.md更新  
- [ ] SESSION_SCRIPT_ISSUE56.md作成

---

## 🔗 **関連ファイル** (参考)
- Issue #46実装結果 (既存データ編集システム)
- Utils/AppError.swift (Issue #35成果)
- Utils/ErrorHandler.swift (Issue #35成果)
- Components/Cards/BaseCard.swift
- 既存CRUD実装ファイル群

---

*Created: 2025-08-13*  
*Updated: 2025-08-13 (Post Issue #35 Completion)*  
*Target: Issue #60 Complete Implementation*  
*Strategic Position: 開発速度乗数効果 - Priority #3*  
*Previous: Issue #35 (✅ Completed - 統一エラーハンドリング戦略)*  
*Next: SESSION_SCRIPT_ISSUE56.md (Priority #4 - ホーム画面改善)*