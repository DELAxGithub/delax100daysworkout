# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building the Project
```bash
# Build the iOS app using build script
./build.sh

# Direct Xcode build
xcodebuild build -project Delax100DaysWorkout.xcodeproj -scheme Delax100DaysWorkout -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=latest'
```

### Xcode Project Management
```bash
# Update Xcode project with new Swift files
./scripts/update_xcode_project.sh

# Add specific file to Xcode project
python3 scripts/add_to_xcode.py <file_path> <group_name>
```

### Security and Git Hooks
```bash
# Setup git hooks for security checks
./scripts/setup_git_hooks.sh

# Check for secrets in code
python3 scripts/check_secrets.py
```

## Architecture Overview

This is a comprehensive iOS fitness training app built with SwiftUI and SwiftData, supporting cycling, strength training, and flexibility workouts.

### Core Architecture Layers

**Models (SwiftData)**
- `DailyLog`, `WorkoutRecord`, `WeeklyTemplate`, `DailyTask` - Core data models
- `UserProfile`, `Achievement`, `WeeklyReport` - User and progress tracking
- `CyclingDetail`, `StrengthDetail`, `FlexibilityDetail` - Workout-specific data

**Services Layer**
- `WeeklyPlanManager` - AI-powered weekly workout plan optimization
- `ProgressAnalyzer` - Performance analysis and trend detection  
- `WeeklyPlanAIService` - Claude AI integration for workout suggestions
- `BugReportManager` - Automated bug reporting to GitHub Issues
- `GitHubService` - GitHub API integration
- `TaskSuggestionManager` - Dynamic task recommendations

**Features (SwiftUI Views)**
- `TodayView` - Daily task management with progress tracking
- `DashboardView` - Overview of fitness metrics and achievements
- `WeeklyReview` - AI-powered weekly performance analysis
- `SettingsView` - App configuration and preferences
- Specialized workout input views for each training type

### Key Integrations

**AI Workflow System**
- Integrated with Claude AI for workout optimization
- Automatic weekly plan adjustments based on performance data
- Cost-aware AI usage with configurable limits
- Manual and automatic update triggers

**Automated Bug Reporting**
- Shake gesture (3x) triggers bug report interface
- Automatic GitHub Issue creation with device/app context
- Integration with Claude AI for automated bug analysis and fixing

**Data Flow**
- SwiftData for local persistence across all models
- ObservableObject ViewModels for state management
- Combine framework for reactive updates
- Environment injection for ModelContext throughout view hierarchy

## Project Structure Conventions

**File Organization**
- `Models/` - SwiftData model classes
- `Features/` - SwiftUI views organized by functionality
- `Services/` - Business logic and external service integrations
- `Utils/` - Utility classes and extensions
- `Application/` - App configuration and main app structure

**Naming Patterns**
- Views: `[Feature]View.swift` (e.g., `TodayView.swift`)
- ViewModels: `[Feature]ViewModel.swift` 
- Services: `[Purpose]Service.swift` or `[Purpose]Manager.swift`
- Models: Descriptive names matching domain concepts

## Development Notes

**SwiftData Context**
- ModelContext is injected via SwiftUI Environment
- All views access shared model container configured in main app
- Use `@Environment(\.modelContext)` for database operations

**AI Service Integration**
- WeeklyPlanManager handles all AI interactions
- Cost estimation and limits prevent runaway API usage
- Error handling for AI service failures with graceful degradation

**Testing Strategy**
- No specific test framework configured - check with user for testing approach
- Preview providers available for SwiftUI views
- Use iOS Simulator for UI testing

**Localization**
- UI text primarily in Japanese
- Comments and code documentation in Japanese
- Consider locale-specific formatting for dates and numbers

## Spec-Driven Development

description: "spec-driven development"
---

Claude Codeを用いたspec-driven developmentを行います。

## spec-driven development とは

spec-driven development は、以下の5つのフェーズからなる開発手法です。

### 1. 事前準備フェーズ

- ユーザーがClaude Codeに対して、実行したいタスクの概要を伝える
- このフェーズで `mkdir -p ./.cckiro/specs` を実行します
- `./cckiro/specs` 内にタスクの概要から適切な spec 名を考えて、その名前のディレクトリを作成します
    - たとえば、「記事コンポーネントを作成する」というタスクなら `./cckiro/specs/create-article-component` という名前のディレクトリを作成します
- 以下ファイルを作成するときはこのディレクトリの中に作成します

### 2. 要件フェーズ

- Claude Codeがユーザーから伝えられたタスクの概要に基づいて、タスクが満たすべき「要件ファイル」を作成する
- Claude Codeがユーザーに対して「要件ファイル」を提示し、問題がないかを尋ねる
- ユーザーが「要件ファイル」を確認し、問題があればClaude Codeに対してフィードバックする
- ユーザーが「要件ファイル」を確認し、問題がないと答えるまで「要件ファイル」に対して修正を繰り返す

### 3. 設計フェーズ

- Claude Codeは、「要件ファイル」に記載されている要件を満たすような設計を記述した「設計ファイル」を作成する
- Claude Codeがユーザーに対して「設計ファイル」を提示し、問題がないかを尋ねる
- ユーザーが「設計ファイル」を確認し、問題があればClaude Codeに対してフィードバックする
- ユーザーが「設計ファイル」を確認し、問題がないと答えるまで「要件ファイル」に対して修正を繰り返す

### 4. 実装計画フェーズ

- Claude Codeは、「設計ファイル」に記載されている設計を実装するための「実装計画ファイル」を作成する
- Claude Codeがユーザーに対して「実装計画ファイル」を提示し、問題がないかを尋ねる
- ユーザーが「実装計画ファイル」を確認し、問題があればClaude Codeに対してフィードバックする
- ユーザーが「実装計画ファイル」を確認し、問題がないと答えるまで「要件ファイル」に対して修正を繰り返す

### 5. 実装フェーズ

- Claude Codeは、「実装計画ファイル」に基づいて実装を開始する
- 実装するときは「要件ファイル」「設計ファイル」に記載されている内容を守りながら実装してください