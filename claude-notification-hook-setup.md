# Claude Code 通知Hook設定ガイド

このガイドに従って、Claude Codeで通知音付きのhook設定を一発で行えます。どのプロジェクトでも再利用可能です。

## 📋 設定手順

### 1. Hooks設定を開く
Claude Codeで以下のコマンドを実行：
```
/hooks
```

### 2. Notificationイベントを選択
- `Notification` イベントを選択
- `+ Add new matcher…` を選択
- `*` (全ツール対象) を入力

### 3. Hook コマンドを追加
`+ Add new hook…` を選択し、以下のコマンドを入力：

```bash
osascript -e "display notification \"Claude Code作業中\" with title \"🤖 Claude Assistant\" sound name \"Blow\""
```

### 4. 保存設定
- **User settings** を選択（全プロジェクトで有効）
- Escキーで設定画面を閉じる

## 🔊 通知音バリエーション

好みに応じて音を変更できます：

```bash
# 軽やかな音
osascript -e "display notification \"Claude Code作業中\" with title \"🤖 Claude Assistant\" sound name \"Glass\""

# 達成感のある音
osascript -e "display notification \"Claude Code作業中\" with title \"🤖 Claude Assistant\" sound name \"Hero\""

# 注意喚起音
osascript -e "display notification \"Claude Code作業中\" with title \"🤖 Claude Assistant\" sound name \"Ping\""

# 警告音
osascript -e "display notification \"Claude Code作業中\" with title \"🤖 Claude Assistant\" sound name \"Basso\""

# 特別な音
osascript -e "display notification \"Claude Code作業中\" with title \"🤖 Claude Assistant\" sound name \"Submarine\""
```

## 📝 完成版設定JSON

設定後、`~/.claude/settings.json`は以下のようになります：

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e \"display notification \\\"Claude Code作業中\\\" with title \\\"🤖 Claude Assistant\\\" sound name \\\"Blow\\\"\""
          }
        ]
      }
    ]
  }
}
```

## 🧪 動作テスト

設定後、以下で動作確認：

1. Claude Codeで何かタスクを実行
2. Claude Codeが応答完了時に通知音が鳴ることを確認
3. macOS通知センターに通知が表示されることを確認

## 🔧 トラブルシューティング

### 通知が表示されない場合
1. macOSの通知設定で「ターミナル」の通知が許可されているか確認
2. `osascript`コマンドが実行可能か確認：
   ```bash
   osascript -e "display notification \"テスト\" with title \"テスト\""
   ```

### 音が鳴らない場合
1. macOSのサウンド設定を確認
2. 利用可能な通知音を確認：
   ```bash
   ls /System/Library/Sounds/
   ```

### 設定が反映されない場合
1. Claude Codeを再起動
2. `~/.claude/settings.json`の構文エラーをチェック

## 🎯 応用例

### 作業時間帯で音を変える
```bash
hour=$(date +%H); if [ $hour -ge 9 ] && [ $hour -lt 17 ]; then sound="Ping"; else sound="Glass"; fi; osascript -e "display notification \"Claude Code作業中\" with title \"🤖 Claude Assistant\" sound name \"$sound\""
```

### カスタムメッセージ
```bash
osascript -e "display notification \"$(date '+%H:%M') - タスク完了\" with title \"🤖 Claude Assistant\" sound name \"Hero\""
```

## 📖 参考資料

- [Claude Code Hooks公式ドキュメント](https://docs.anthropic.com/en/docs/claude-code/hooks)
- [macOS osascript Reference](https://ss64.com/osx/osascript.html)

---

*このガイドで設定したhookは全てのClaude Codeプロジェクトで動作します。*