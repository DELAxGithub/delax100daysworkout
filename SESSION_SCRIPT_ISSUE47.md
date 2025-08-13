# SESSION_SCRIPT_ISSUE47.md
## 🎯 ドラッグ&ドロップ機能: SwiftUI標準実装

### 🎯 セッション目標
Issue #47を一気通貫で完全実装し、シミュレーションビルドが通るまで確認

### 🎯 戦略的位置づけ
**最高インパクト/最低リスク**: ユーザーが即座に体感するネイティブUX向上 (新優先度 #1)

---

## 📋 **一気通貫実行プロンプト**

```
Claude、Issue #47 (🎯 ドラッグ&ドロップ機能: SwiftUI標準実装) を一気通貫で実装してください。

## 🎯 実行内容
1. **Issue #47の要求内容確認**: GitHub issueの詳細を正確に理解
2. **SwiftUIドラッグ&ドロップ機能実装**: 
   - WeeklyScheduleView タスク並び替え機能
   - WorkoutRecord 順序変更機能
   - 統一ドラッグハンドル UI実装
   - ハプティックフィードバック統合
3. **実装確認**: シミュレーションビルドが通ることを確認
4. **Issue #47をクローズ**: GitHub上でクローズ
5. **PROGRESS.md更新**: 完了状況を反映
6. **次セッションスクリプト作成**: SESSION_SCRIPT_ISSUE35.md作成 (新優先順位による)

## ✅ 受入条件
- [ ] WeeklyScheduleView タスク並び替え
- [ ] WorkoutRecord 履歴並び替え
- [ ] 統一ドラッグハンドルUI
- [ ] ハプティックフィードバック
- [ ] アクセシビリティ対応
- [ ] エラーハンドリング
- [ ] BUILD SUCCEEDED確認

## 📌 制約
- 1セッション1イシューの原則を守る
- Issue #47のみに集中し、他のイシューには手を出さない
- 部分実装は避け、完全実装まで実行する
- 既存UIコンポーネント(BaseCard, HapticManager)を最大限活用

完了したら「Issue #47完全実装完了、次セッション準備完了」とお知らせください。
```

---

## 📋 **実装チェックリスト** (参考)

### Phase 1: 要求分析
- [ ] Issue #47詳細確認
- [ ] 現在のドラッグ機能調査
- [ ] SwiftUI標準API確認

### Phase 2: ドラッグ&ドロップ実装
- [ ] WeeklyScheduleView並び替え機能
- [ ] WorkoutRecord順序変更機能  
- [ ] 統一ドラッグハンドルUI
- [ ] ハプティックフィードバック統合

### Phase 3: UX強化
- [ ] アクセシビリティ対応
- [ ] エラーハンドリング
- [ ] 視覚的フィードバック改善

### Phase 4: 品質確認
- [ ] BUILD SUCCEEDED確認
- [ ] 基本動作テスト
- [ ] UX確認

### Phase 5: 完了処理
- [ ] Issue #47クローズ
- [ ] PROGRESS.md更新
- [ ] SESSION_SCRIPT_ISSUE35.md作成

---

## 🔗 **関連ファイル** (参考)
- WeeklyScheduleView.swift
- WorkoutHistoryComponents.swift
- HapticManager.swift
- BaseCard.swift
- EditableTaskCard.swift

---

*Created: 2025-08-13*  
*Target: Issue #47 Complete Implementation*  
*Next: SESSION_SCRIPT_ISSUE35.md (Priority #2)*