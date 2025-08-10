# 🏗️ トレーニング貯金システム：設計仕様書

## 📐 アーキテクチャ設計

### システム構成図
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   UI Layer      │    │  Service Layer  │    │   Data Layer    │
│                 │    │                 │    │                 │
│ SavingsViews    │◄──►│TrainingSavings  │◄──►│ TrainingSavings │
│ DashboardView   │    │Manager          │    │ WorkoutRecord   │
│ DetailViews     │    │                 │    │ Achievement     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ SwiftUI Charts  │    │ ProgressAnalyzer│    │   SwiftData     │
│ Animations      │    │ Achievement     │    │   ModelContext  │
│ State Management│    │ Integration     │    │   Persistence   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

---

## 🗃️ データモデル設計

### TrainingSavings モデル
```swift
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
    
    // リレーション
    var achievements: [Achievement]
    
    init(savingsType: SavingsType, targetCount: Int) {
        self.id = UUID()
        self.savingsType = savingsType
        self.currentCount = 0
        self.targetCount = targetCount
        self.resetPeriod = savingsType.defaultResetPeriod
        self.createdDate = Date()
        self.lastUpdated = Date()
        self.achievedMilestones = []
        self.isActive = true
        self.currentStreakCount = 0
        self.longestStreakCount = 0
        self.achievements = []
    }
}
```

### SavingsType 列挙型
```swift
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
    
    var defaultTarget: Int {
        switch self {
        case .sstCounter: return 100
        case .pushVolume: return 120  // 月間セット数
        case .pullVolume: return 100  // 月間セット数
        case .legsVolume: return 80   // 月間セット数
        case .forwardSplitStreak: return 30  // 30日連続
        case .sideSplitStreak: return 30     // 30日連続
        case .forwardBendStreak: return 30   // 30日連続
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
        case .pushVolume, .pullVolume, .legsVolume: return [25, 50, 75, 100] // 達成率%
        case .forwardSplitStreak, .sideSplitStreak, .forwardBendStreak: return [7, 14, 30, 60, 100]
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

### SavingsProgress 構造体
```swift
struct SavingsProgress {
    let savingsType: SavingsType
    let currentCount: Int
    let targetCount: Int
    let progressPercentage: Double
    let nextMilestone: Int?
    let remainingToNextMilestone: Int?
    let isStreakType: Bool
    let currentStreak: Int?
    let longestStreak: Int?
    let lastUpdated: Date
    
    var progressRatio: Double {
        guard targetCount > 0 else { return 0 }
        return min(Double(currentCount) / Double(targetCount), 1.0)
    }
}
```

---

## 🔧 サービス層設計

### TrainingSavingsManager
```swift
class TrainingSavingsManager: ObservableObject {
    private let modelContext: ModelContext
    private let progressAnalyzer: ProgressAnalyzer
    
    @Published var allSavings: [TrainingSavings] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Core Methods
    func initializeDefaultSavings()
    func updateSavingsFromWorkout(_ workout: WorkoutRecord)
    func calculateProgress(for savingsType: SavingsType) -> SavingsProgress?
    func checkForMilestoneAchievements(_ savings: TrainingSavings) -> [Achievement]
    func resetMonthlySavings()
    func refreshAllSavings()
    
    // MARK: - Specific Update Methods
    private func updateSSTCounter(from workout: WorkoutRecord)
    private func updateVolumeCounter(from workout: WorkoutRecord)
    private func updateFlexibilityStreak(from workout: WorkoutRecord)
    
    // MARK: - Helper Methods
    private func shouldCountAsSST(_ cyclingDetail: CyclingDetail, ftp: Int) -> Bool
    private func extractMuscleGroupSets(from strengthDetails: [StrengthDetail]) -> (push: Int, pull: Int, legs: Int)
    private func checkStreakContinuity(for savingsType: SavingsType, date: Date) -> Bool
}
```

### WorkoutAnalyzer 拡張
```swift
extension ProgressAnalyzer {
    
    // SST判定ロジック
    func isQualifiedSST(cyclingDetail: CyclingDetail, currentFTP: Int) -> Bool {
        guard cyclingDetail.duration >= 20 * 60 else { return false } // 20分以上
        guard currentFTP > 0 else { return false }
        
        let sstLowerBound = Double(currentFTP) * 0.88  // FTPの88%
        let sstUpperBound = Double(currentFTP) * 0.94  // FTPの94%
        
        return cyclingDetail.averagePower >= sstLowerBound && 
               cyclingDetail.averagePower <= sstUpperBound
    }
    
    // 筋群判定ロジック
    func categorizeMuscleGroup(_ exerciseName: String) -> MuscleGroup? {
        let pushExercises = ["ベンチプレス", "ショルダープレス", "ディップス", "腕立て伏せ", "チェストプレス"]
        let pullExercises = ["懸垂", "プルアップ", "チンアップ", "ラットプルダウン", "ローイング", "デッドリフト"]
        let legsExercises = ["スクワット", "ランジ", "レッグプレス", "カーフレイズ", "ヒップスラスト", "プランク"]
        
        if pushExercises.contains(where: { exerciseName.contains($0) }) {
            return .push
        } else if pullExercises.contains(where: { exerciseName.contains($0) }) {
            return .pull
        } else if legsExercises.contains(where: { exerciseName.contains($0) }) {
            return .legs
        }
        return nil
    }
}

enum MuscleGroup: String, Codable {
    case push = "Push"
    case pull = "Pull" 
    case legs = "Legs"
}
```

---

## 🎨 UI/UX設計

### 画面構成
```
SavingsDashboardView
├── SavingsOverviewCard (4つの貯金システム概要)
├── SavingsDetailView
│   ├── SSTCounterDetailView
│   ├── VolumeDetailView  
│   └── StreakDetailView
└── AchievementBadgeView
```

### SavingsDashboardView
```swift
struct SavingsDashboardView: View {
    @StateObject private var savingsManager = TrainingSavingsManager()
    @State private var selectedSavingsType: SavingsType?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    // 概要カード
                    SavingsOverviewCardView(
                        savingsProgress: savingsManager.allProgress
                    )
                    
                    // 個別進捗カード
                    ForEach(SavingsType.allCases, id: \.self) { type in
                        SavingsProgressCard(
                            progress: savingsManager.getProgress(for: type),
                            onTap: { selectedSavingsType = type }
                        )
                    }
                    
                    // 最近の達成バッジ
                    RecentAchievementBadges(
                        achievements: savingsManager.recentSavingsAchievements
                    )
                }
                .padding()
            }
            .navigationTitle("トレーニング貯金")
            .sheet(item: $selectedSavingsType) { type in
                SavingsDetailView(savingsType: type)
            }
        }
    }
}
```

### SavingsProgressCard
```swift
struct SavingsProgressCard: View {
    let progress: SavingsProgress
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // アイコン
                Image(systemName: progress.savingsType.iconName)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 40, height: 40)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(progress.savingsType.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if progress.isStreakType {
                        HStack {
                            Text("現在: \(progress.currentStreak ?? 0)日")
                            Spacer()
                            Text("最長: \(progress.longestStreak ?? 0)日")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    } else {
                        HStack {
                            Text("\(progress.currentCount)/\(progress.targetCount)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text("\(Int(progress.progressPercentage))%")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Spacer()
                
                // 進捗サークル
                CircularProgressView(
                    progress: progress.progressRatio,
                    lineWidth: 4,
                    size: 50
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

### CircularProgressView
```swift
struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .cyan]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: progress)
        }
    }
}
```

---

## 🔄 データフロー設計

### ワークアウト完了時のフロー
```
1. WorkoutRecord.isCompleted = true
   ↓
2. TrainingSavingsManager.updateSavingsFromWorkout()
   ↓
3. savingsType別の更新処理
   ├── SST: FTP基準で強度チェック → カウント増加
   ├── Volume: 筋群判定 → セット数加算
   └── Streak: 継続性チェック → ストリーク更新
   ↓
4. マイルストーン達成チェック
   ↓ (達成時)
5. Achievement作成 & 通知表示
   ↓
6. UI更新 (SwiftUI @Published)
```

### 月次リセットフロー
```
1. アプリ起動時 or 日付変更検知
   ↓
2. TrainingSavingsManager.checkMonthlyReset()
   ↓
3. resetPeriod == .monthly のSavingsをリセット
   ↓
4. 前月達成状況に基づいてAchievement作成
   ↓
5. UI更新
```

---

## 🎯 アニメーション設計

### カウントアップアニメーション
```swift
struct CountUpAnimationView: View {
    @State private var displayCount: Int = 0
    let targetCount: Int
    let duration: Double = 1.0
    
    var body: some View {
        Text("\(displayCount)")
            .font(.system(size: 32, weight: .bold, design: .rounded))
            .onAppear {
                animateCount()
            }
            .onChange(of: targetCount) { _, newValue in
                animateCount()
            }
    }
    
    private func animateCount() {
        let steps = max(targetCount / 10, 1)
        let stepDuration = duration / Double(steps)
        
        for i in 0...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                displayCount = min(Int(Double(targetCount) * Double(i) / Double(steps)), targetCount)
            }
        }
    }
}
```

### マイルストーン達成時の効果
```swift
struct MilestoneAchievementView: View {
    @State private var isAnimating = false
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
                .scaleEffect(scale)
                .opacity(opacity)
            
            Text("マイルストーン達成！")
                .font(.title2)
                .fontWeight(.bold)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
```

---

## 📊 テスト設計

### 単体テスト
```swift
class TrainingSavingsManagerTests: XCTestCase {
    
    func testSSTCounterUpdate() {
        // Given: FTP 250W, 20分間のワークアウト, 平均225W (90%)
        // When: updateSavingsFromWorkout()
        // Then: SSTカウンターが1増加
    }
    
    func testVolumeCounterUpdate() {
        // Given: ベンチプレス 3セット, プルアップ 4セット
        // When: updateSavingsFromWorkout()
        // Then: Push=3, Pull=4 加算
    }
    
    func testStreakContinuity() {
        // Given: 昨日柔軟性記録あり
        // When: 今日も柔軟性記録
        // Then: ストリーク継続
    }
    
    func testMilestoneAchievement() {
        // Given: SSTカウンター9回
        // When: 1回追加でカウンター10回
        // Then: 10回マイルストーンAchievement作成
    }
}
```

---

## 🔐 セキュリティ・プライバシー設計

### データ保護
- SwiftData の暗号化機能利用
- ユーザーデータのローカル保存のみ
- クラウド同期は将来拡張で検討

### アクセス制御
- モデルアクセスはModelContext経由のみ
- UI層からの直接データベース操作禁止
- Service層での入力検証実装

---

## 📈 パフォーマンス設計

### データベース最適化
- SavingsType別のインデックス作成
- 頻繁なクエリのキャッシュ実装
- バッチ更新によるトランザクション最適化

### UI最適化
- LazyVStack による仮想化
- 重い計算処理の非同期化
- 画像・アニメーションの最適化

---

## 🚀 デプロイ・運用設計

### リリース戦略
- 段階的ロールアウト（β版 → 正式版）
- 既存ユーザーへの影響最小限の移行
- ロールバック可能な設計

### 監視・メトリクス
- 各貯金システムの利用率追跡
- マイルストーン達成率の監視
- パフォーマンス指標の定期チェック

---

これで設計仕様書は完成です。次のフェーズで詳細な実装計画を策定し、実装に移ります。