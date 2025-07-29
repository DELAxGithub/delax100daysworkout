#!/bin/bash

# 新しいファイルをXcodeプロジェクトに追加するスクリプト
# 使用方法: ./update_xcode_project.sh

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
XCODE_DIR="$PROJECT_ROOT/Delax100DaysWorkout"

echo "🔄 Xcodeプロジェクトを更新しています..."

# 新しく追加されたSwiftファイルを検出
cd "$XCODE_DIR"

# Modelsフォルダの新しいファイル
for file in Delax100DaysWorkout/Models/*.swift; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        # プロジェクトファイルに含まれているかチェック
        if ! grep -q "$filename" Delax100DaysWorkout.xcodeproj/project.pbxproj; then
            echo "📝 Adding $filename to Models group..."
            python3 "$SCRIPT_DIR/add_to_xcode.py" "$file" "Models"
        fi
    fi
done

# Featuresフォルダの新しいファイル
for file in Delax100DaysWorkout/Features/**/*.swift; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        # プロジェクトファイルに含まれているかチェック
        if ! grep -q "$filename" Delax100DaysWorkout.xcodeproj/project.pbxproj; then
            # 親フォルダを取得
            parent_dir=$(dirname "$file" | xargs basename)
            echo "📝 Adding $filename to Features/$parent_dir group..."
            python3 "$SCRIPT_DIR/add_to_xcode.py" "$file" "Features"
        fi
    fi
done

# Servicesフォルダの新しいファイル（今後作成予定）
if [ -d "Delax100DaysWorkout/Services" ]; then
    for file in Delax100DaysWorkout/Services/*.swift; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            if ! grep -q "$filename" Delax100DaysWorkout.xcodeproj/project.pbxproj; then
                echo "📝 Adding $filename to Services group..."
                python3 "$SCRIPT_DIR/add_to_xcode.py" "$file" "Services"
            fi
        fi
    done
fi

echo "✅ Xcodeプロジェクトの更新が完了しました"