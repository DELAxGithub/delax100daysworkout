#!/bin/bash

# Delax100DaysWorkout ビルドスクリプト
# VS Code から Xcode プロジェクトをビルドするためのスクリプト

set -e

echo "🏗️  Delax100DaysWorkout をビルドしています..."

# プロジェクトディレクトリに移動
cd Delax100DaysWorkout

# Clean build
echo "🧹 古いビルドをクリーンアップ中..."
xcodebuild clean \
    -project Delax100DaysWorkout.xcodeproj \
    -scheme Delax100DaysWorkout \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest'

# Build
echo "🔨 ビルド実行中..."
xcodebuild build \
    -project Delax100DaysWorkout.xcodeproj \
    -scheme Delax100DaysWorkout \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest' \
    -configuration Debug \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

echo "✅ ビルドが完了しました！"