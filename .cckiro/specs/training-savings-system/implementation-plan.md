# 🚀 トレーニング貯金システム：実装計画

## 📋 実装フェーズ

### Phase 1: データモデル実装 (Day 1-2)
1. **TrainingSavings.swift** 作成
2. **SavingsType.swift** 列挙型定義
3. **SwiftData スキーマ統合**
4. **既存Achievement システム拡張**

### Phase 2: サービス層実装 (Day 3-5)
1. **TrainingSavingsManager.swift** 作成
2. **ProgressAnalyzer 拡張**
3. **ワークアウト解析ロジック実装**
4. **マイルストーン達成検知**

### Phase 3: UI コンポーネント実装 (Day 6-9)
1. **基本UIコンポーネント作成**
2. **SavingsDashboardView 実装**
3. **詳細画面とアニメーション**
4. **既存ダッシュボード統合**

### Phase 4: テスト・仕上げ (Day 10-12)
1. **単体テスト作成**
2. **UI/UXテスト**
3. **パフォーマンス最適化**
4. **ドキュメント更新**

---

## 📁 ファイル構成

```
Delax100DaysWorkout/
├── Models/
│   ├── TrainingSavings.swift          # 新規作成
│   ├── SavingsType.swift              # 新規作成
│   └── Achievement.swift              # 拡張
├── Services/
│   ├── TrainingSavingsManager.swift   # 新規作成
│   └── ProgressAnalyzer.swift         # 拡張
├── Features/
│   └── Savings/                       # 新規ディレクトリ
│       ├── SavingsDashboardView.swift
│       ├── SavingsProgressCard.swift
│       ├── SavingsDetailView.swift
│       ├── CircularProgressView.swift
│       ├── CountUpAnimationView.swift
│       └── MilestoneAchievementView.swift
└── Utils/
    └── MuscleGroupAnalyzer.swift      # 新規作成
```

---

## 🔧 実装詳細

### Step 1: TrainingSavings モデル実装

**ファイル**: `Models/TrainingSavings.swift`

```swift
import Foundation
import SwiftData

@Model
final class TrainingSavings {
    var id: UUID
    var savingsType: SavingsType
    var currentCount: Int
    var targetCount: Int
    var resetPeriod: ResetPeriod
    var createdDate: Date
    var lastUpdated: Date
    var lastResetDate: Date?
    var achievedMilestones: [Int]
    var isActive: Bool
    
    // ストリーク専用フィールド
    var currentStreakCount: Int
    var longestStreakCount: Int
    var lastStreakDate: Date?
    
    // 計算プロパティ
    var progressRatio: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(currentCount) / Double(targetCount), 1.0)
    }
    
    var nextMilestone: Int? {
        let milestones = savingsType.milestones
        return milestones.first { $0 > currentCount }
    }
    
    init(savingsType: SavingsType, targetCount: Int? = nil) {
        self.id = UUID()
        self.savingsType = savingsType
        self.currentCount = 0
        self.targetCount = targetCount ?? savingsType.defaultTarget
        self.resetPeriod = savingsType.defaultResetPeriod
        self.createdDate = Date()
        self.lastUpdated = Date()
        self.achievedMilestones = []
        self.isActive = true
        self.currentStreakCount = 0
        self.longestStreakCount = 0
    }
}
```

### Step 2: SavingsType 列挙型実装

**ファイル**: `Models/SavingsType.swift`

```swift
import Foundation

enum SavingsType: String, Codable, CaseIterable {
    case sstCounter = "SST累積"
    case pushVolume = "Push貯金"
    case pullVolume = "Pull貯金" 
    case legsVolume = "Legs貯金"
    case forwardSplitStreak = "前後開脚ストリーク"
    case sideSplitStreak = "左右開脚ストリーク"
    case forwardBendStreak = "前屈ストリーク"
    
    var iconName: String {
        switch self {
        case .sstCounter: return "bolt.circle.fill"
        case .pushVolume: return "figure.strengthtraining.traditional"
        case .pullVolume: return "figure.pull.ups"
        case .legsVolume: return "figure.squat"
        case .forwardSplitStreak: return "figure.flexibility"
        case .sideSplitStreak: return "figure.mind.and.body"
        case .forwardBendStreak: return "figure.roll"
        }
    }
    
    var color: Color {
        switch self {
        case .sstCounter: return .blue
        case .pushVolume: return .red
        case .pullVolume: return .green
        case .legsVolume: return .orange
        case .forwardSplitStreak: return .purple
        case .sideSplitStreak: return .pink
        case .forwardBendStreak: return .cyan
        }
    }
    
    var defaultTarget: Int {
        switch self {
        case .sstCounter: return 100
        case .pushVolume: return 120
        case .pullVolume: return 100
        case .legsVolume: return 80
        case .forwardSplitStreak, .sideSplitStreak, .forwardBendStreak: return 30
        }
    }
    
    var defaultResetPeriod: ResetPeriod {
        switch self {
        case .sstCounter: return .never
        case .pushVolume, .pullVolume, .legsVolume: return .monthly
        case .forwardSplitStreak, .sideSplitStreak, .forwardBendStreak: return .never
        }
    }
    
    var milestones: [Int] {
        switch self {
        case .sstCounter: return [10, 25, 50, 75, 100]
        case .pushVolume, .pullVolume, .legsVolume: return [25, 50, 75, 100]
        case .forwardSplitStreak, .sideSplitStreak, .forwardBendStreak: return [7, 14, 30, 60, 100]
        }
    }
    
    var isStreakType: Bool {
        switch self {
        case .forwardSplitStreak, .sideSplitStreak, .forwardBendStreak: return true
        default: return false
        }
    }
}

enum ResetPeriod: String, Codable {
    case never = "リセットなし"
    case daily = "日次"
    case weekly = "週次"
    case monthly = "月次"
    case yearly = "年次"
}
```

### Step 3: TrainingSavingsManager サービス実装

**ファイル**: `Services/TrainingSavingsManager.swift`

```swift
import Foundation
import SwiftData
import Combine

class TrainingSavingsManager: ObservableObject {
    private var modelContext: ModelContext?
    private let progressAnalyzer: ProgressAnalyzer
    
    @Published var allSavings: [TrainingSavings] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        self.progressAnalyzer = ProgressAnalyzer(modelContext: modelContext!)
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        self.progressAnalyzer = ProgressAnalyzer(modelContext: context)
        initializeDefaultSavings()
        loadAllSavings()
    }
    
    // MARK: - 初期化
    func initializeDefaultSavings() {
        guard let modelContext = modelContext else { return }
        
        for savingsType in SavingsType.allCases {
            let descriptor = FetchDescriptor<TrainingSavings>(
                predicate: #Predicate<TrainingSavings> { savings in
                    savings.savingsType == savingsType
                }
            )
            
            do {
                let existing = try modelContext.fetch(descriptor)
                if existing.isEmpty {
                    let newSavings = TrainingSavings(savingsType: savingsType)
                    modelContext.insert(newSavings)
                }
            } catch {
                errorMessage = "初期化エラー: \(error.localizedDescription)"
            }
        }
        
        do {
            try modelContext.save()
        } catch {
            errorMessage = "保存エラー: \(error.localizedDescription)"
        }
    }
    
    // MARK: - データ読み込み
    func loadAllSavings() {
        guard let modelContext = modelContext else { return }
        
        isLoading = true
        
        let descriptor = FetchDescriptor<TrainingSavings>(
            predicate: #Predicate<TrainingSavings> { savings in
                savings.isActive == true
            },
            sortBy: [SortDescriptor(\.savingsType)]
        )
        
        do {
            allSavings = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "データ読み込みエラー: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - ワークアウト更新処理
    func updateSavingsFromWorkout(_ workout: WorkoutRecord) {
        guard workout.isCompleted else { return }
        
        switch workout.workoutType {
        case .cycling:
            updateSSTCounter(from: workout)
        case .strength:
            updateVolumeCounters(from: workout)
        case .flexibility:
            updateFlexibilityStreaks(from: workout)
        }
        
        checkMonthlyReset()
        saveChanges()
    }
    
    // MARK: - SST カウンター更新
    private func updateSSTCounter(from workout: WorkoutRecord) {
        guard let cyclingDetail = workout.cyclingDetail,
              let currentFTP = getCurrentFTP() else { return }
        
        let isSST = progressAnalyzer.isQualifiedSST(
            cyclingDetail: cyclingDetail, 
            currentFTP: currentFTP
        )
        
        if isSST {
            if let sstSavings = getSavings(for: .sstCounter) {
                sstSavings.currentCount += 1
                sstSavings.lastUpdated = Date()
                checkForMilestoneAchievements(sstSavings)
            }
        }
    }
    
    // MARK: - ボリューム カウンター更新
    private func updateVolumeCounters(from workout: WorkoutRecord) {
        guard let strengthDetails = workout.strengthDetails else { return }
        
        let volumeCount = progressAnalyzer.extractMuscleGroupSets(from: strengthDetails)
        
        // Push ボリューム更新
        if volumeCount.push > 0, let pushSavings = getSavings(for: .pushVolume) {
            pushSavings.currentCount += volumeCount.push
            pushSavings.lastUpdated = Date()
            checkForMilestoneAchievements(pushSavings)
        }
        
        // Pull ボリューム更新
        if volumeCount.pull > 0, let pullSavings = getSavings(for: .pullVolume) {
            pullSavings.currentCount += volumeCount.pull
            pullSavings.lastUpdated = Date()
            checkForMilestoneAchievements(pullSavings)
        }
        
        // Legs ボリューム更新
        if volumeCount.legs > 0, let legsSavings = getSavings(for: .legsVolume) {
            legsSavings.currentCount += volumeCount.legs
            legsSavings.lastUpdated = Date()
            checkForMilestoneAchievements(legsSavings)
        }
    }
    
    // MARK: - 柔軟性ストリーク更新
    private func updateFlexibilityStreaks(from workout: WorkoutRecord) {
        guard let flexDetail = workout.flexibilityDetail else { return }
        
        let today = Date()
        
        // 前後開脚チェック
        if flexDetail.forwardSplitLeft > 0 || flexDetail.forwardSplitRight > 0 {
            updateStreakCount(for: .forwardSplitStreak, date: today)
        }
        
        // 左右開脚チェック
        if flexDetail.sideSplitAngle > 0 {
            updateStreakCount(for: .sideSplitStreak, date: today)
        }
        
        // 前屈チェック
        if flexDetail.forwardBendDistance > 0 {
            updateStreakCount(for: .forwardBendStreak, date: today)
        }
    }
    
    // MARK: - ヘルパーメソッド
    private func getSavings(for type: SavingsType) -> TrainingSavings? {
        return allSavings.first { $0.savingsType == type }
    }
    
    private func getCurrentFTP() -> Int? {
        // FTPHistory から最新のFTP値を取得
        guard let modelContext = modelContext else { return nil }
        
        let descriptor = FetchDescriptor<FTPHistory>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        do {
            let ftpHistory = try modelContext.fetch(descriptor)
            return ftpHistory.first?.ftpValue
        } catch {
            return nil
        }
    }
    
    private func updateStreakCount(for type: SavingsType, date: Date) {
        guard let savings = getSavings(for: type) else { return }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        
        if let lastStreakDate = savings.lastStreakDate {
            let lastDay = calendar.startOfDay(for: lastStreakDate)
            let daysDiff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysDiff == 1 {
                // 連続記録継続
                savings.currentStreakCount += 1
                savings.longestStreakCount = max(savings.longestStreakCount, savings.currentStreakCount)
            } else if daysDiff > 1 {
                // ストリーク中断
                savings.currentStreakCount = 1
            }
            // daysDiff == 0 の場合は今日既に記録済み
        } else {
            // 初回記録
            savings.currentStreakCount = 1
            savings.longestStreakCount = 1
        }
        
        savings.lastStreakDate = today
        savings.lastUpdated = Date()
        checkForMilestoneAchievements(savings)
    }
    
    private func checkForMilestoneAchievements(_ savings: TrainingSavings) {
        let milestones = savings.savingsType.milestones
        let currentValue = savings.savingsType.isStreakType ? savings.currentStreakCount : savings.currentCount
        
        for milestone in milestones {
            if currentValue >= milestone && !savings.achievedMilestones.contains(milestone) {
                savings.achievedMilestones.append(milestone)
                createMilestoneAchievement(savings: savings, milestone: milestone)
            }
        }
    }
    
    private func createMilestoneAchievement(savings: TrainingSavings, milestone: Int) {
        guard let modelContext = modelContext else { return }
        
        let achievement = Achievement(
            type: .milestone,
            title: "\(savings.savingsType.rawValue) \(milestone)達成！",
            description: savings.savingsType.isStreakType ? 
                "\(milestone)日連続達成しました！" : 
                "\(milestone)回/セットを達成しました！",
            workoutType: nil,
            value: "\(milestone)"
        )
        
        modelContext.insert(achievement)
    }
    
    private func checkMonthlyReset() {
        let calendar = Calendar.current
        let now = Date()
        
        for savings in allSavings where savings.resetPeriod == .monthly {
            if let lastReset = savings.lastResetDate {
                if !calendar.isDate(lastReset, equalTo: now, toGranularity: .month) {
                    // 月が変わった場合、リセット
                    savings.currentCount = 0
                    savings.lastResetDate = now
                    savings.lastUpdated = now
                }
            } else {
                // 初回の場合、今月の開始日に設定
                savings.lastResetDate = calendar.dateInterval(of: .month, for: now)?.start
            }
        }
    }
    
    private func saveChanges() {
        guard let modelContext = modelContext else { return }
        
        do {
            try modelContext.save()
            loadAllSavings() // UI更新のため再読み込み
        } catch {
            errorMessage = "保存エラー: \(error.localizedDescription)"
        }
    }
}
```

### Step 4: UI コンポーネント実装

**ファイル**: `Features/Savings/SavingsDashboardView.swift`

```swift
import SwiftUI
import SwiftData

struct SavingsDashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var savingsManager = TrainingSavingsManager()
    @State private var selectedSavingsType: SavingsType?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // 概要カード
                    SavingsOverviewCard(allSavings: savingsManager.allSavings)
                    
                    // 個別進捗カード
                    ForEach(SavingsType.allCases, id: \.self) { type in
                        if let savings = savingsManager.allSavings.first(where: { $0.savingsType == type }) {
                            SavingsProgressCard(
                                savings: savings,
                                onTap: { selectedSavingsType = type }
                            )
                        }
                    }
                    
                    // 最近の達成バッジ
                    RecentAchievementBadges()
                }
                .padding()
            }
            .navigationTitle("トレーニング貯金")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                savingsManager.loadAllSavings()
            }
            .sheet(item: $selectedSavingsType) { type in
                SavingsDetailView(savingsType: type)
            }
        }
        .onAppear {
            savingsManager.setModelContext(modelContext)
        }
        .alert("エラー", isPresented: .constant(savingsManager.errorMessage != nil)) {
            Button("OK") {
                savingsManager.errorMessage = nil
            }
        } message: {
            if let error = savingsManager.errorMessage {
                Text(error)
            }
        }
    }
}
```

---

## 🧪 テスト戦略

### 単体テスト実装

**ファイル**: `Tests/TrainingSavingsManagerTests.swift`

```swift
import XCTest
import SwiftData
@testable import Delax100DaysWorkout

final class TrainingSavingsManagerTests: XCTestCase {
    var modelContainer: ModelContainer!
    var savingsManager: TrainingSavingsManager!
    
    override func setUp() {
        super.setUp()
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try! ModelContainer(
            for: TrainingSavings.self, 
            WorkoutRecord.self, 
            FTPHistory.self,
            configurations: config
        )
        
        savingsManager = TrainingSavingsManager()
        savingsManager.setModelContext(modelContainer.mainContext)
    }
    
    func testSSTCounterIncrement() {
        // Given
        let ftpHistory = FTPHistory(ftpValue: 250, measurementMethod: .test)
        modelContainer.mainContext.insert(ftpHistory)
        
        let cyclingDetail = CyclingDetail(
            distance: 25,
            duration: 1200, // 20分
            averagePower: 225, // FTP 250の90%
            maxPower: 280,
            averageHeartRate: 160,
            maxHeartRate: 180
        )
        
        let workout = WorkoutRecord(
            date: Date(),
            workoutType: .cycling,
            duration: 1200,
            isCompleted: true
        )
        workout.cyclingDetail = cyclingDetail
        
        // When
        savingsManager.updateSavingsFromWorkout(workout)
        
        // Then
        let sstSavings = savingsManager.allSavings.first { $0.savingsType == .sstCounter }
        XCTAssertEqual(sstSavings?.currentCount, 1)
    }
    
    func testVolumeCounterIncrement() {
        // Given
        let strengthDetails = [
            StrengthDetail(exercise: "ベンチプレス", weight: 80, sets: 3, reps: 10),
            StrengthDetail(exercise: "懸垂", weight: 0, sets: 4, reps: 8)
        ]
        
        let workout = WorkoutRecord(
            date: Date(),
            workoutType: .strength,
            duration: 3600,
            isCompleted: true
        )
        workout.strengthDetails = strengthDetails
        
        // When
        savingsManager.updateSavingsFromWorkout(workout)
        
        // Then
        let pushSavings = savingsManager.allSavings.first { $0.savingsType == .pushVolume }
        let pullSavings = savingsManager.allSavings.first { $0.savingsType == .pullVolume }
        
        XCTAssertEqual(pushSavings?.currentCount, 3)
        XCTAssertEqual(pullSavings?.currentCount, 4)
    }
    
    func testStreakContinuity() {
        // Given - 昨日の柔軟性記録
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayWorkout = WorkoutRecord(
            date: yesterday,
            workoutType: .flexibility,
            duration: 1200,
            isCompleted: true
        )
        yesterdayWorkout.flexibilityDetail = FlexibilityDetail(
            forwardSplitLeft: 45,
            forwardSplitRight: 43,
            sideSplitAngle: 90,
            forwardBendDistance: 15
        )
        
        savingsManager.updateSavingsFromWorkout(yesterdayWorkout)
        
        // When - 今日の柔軟性記録
        let todayWorkout = WorkoutRecord(
            date: Date(),
            workoutType: .flexibility,
            duration: 1200,
            isCompleted: true
        )
        todayWorkout.flexibilityDetail = FlexibilityDetail(
            forwardSplitLeft: 46,
            forwardSplitRight: 44,
            sideSplitAngle: 92,
            forwardBendDistance: 16
        )
        
        savingsManager.updateSavingsFromWorkout(todayWorkout)
        
        // Then
        let forwardSplitSavings = savingsManager.allSavings.first { $0.savingsType == .forwardSplitStreak }
        XCTAssertEqual(forwardSplitSavings?.currentStreakCount, 2)
    }
}
```

---

## 📊 進捗トラッキング

### 実装チェックリスト

#### Phase 1: データモデル ✅
- [ ] TrainingSavings.swift
- [ ] SavingsType.swift
- [ ] ResetPeriod.swift
- [ ] SwiftData スキーマ統合
- [ ] Achievement 拡張

#### Phase 2: サービス層 ✅
- [ ] TrainingSavingsManager.swift
- [ ] ProgressAnalyzer 拡張
- [ ] MuscleGroupAnalyzer.swift
- [ ] SST判定ロジック
- [ ] ストリーク管理ロジック

#### Phase 3: UI実装 ✅
- [ ] SavingsDashboardView.swift
- [ ] SavingsProgressCard.swift
- [ ] SavingsDetailView.swift
- [ ] CircularProgressView.swift
- [ ] CountUpAnimationView.swift
- [ ] MilestoneAchievementView.swift

#### Phase 4: 統合・テスト ✅
- [ ] 既存ダッシュボード統合
- [ ] 単体テスト実装
- [ ] UI/UXテスト
- [ ] パフォーマンステスト
- [ ] ドキュメント更新

---

## 🎯 品質基準

### コード品質
- Swift コーディング規約準拠
- SwiftLint 警告ゼロ
- 単体テストカバレッジ 80% 以上
- メモリリーク無し

### UI/UX品質
- 60fps での滑らかなアニメーション
- アクセシビリティ対応（VoiceOver）
- ダークモード対応
- 多言語対応準備（日本語優先）

### パフォーマンス
- アプリ起動時間への影響 < 200ms
- データ更新処理 < 2秒
- UI描画遅延 < 100ms

---

この実装計画に従って、段階的にトレーニング貯金システムを構築していきます。各フェーズ完了時に動作確認とテストを実施し、品質を保ちながら進めます。