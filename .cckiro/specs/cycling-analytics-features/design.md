# 自転車トレーニング集計機能　設計書

## 1. システム設計概要

### 1.1 アーキテクチャ概要
```
┌─────────────────────────────────────────────────────────────┐
│                        Presentation Layer                   │
├─────────────────────────────────────────────────────────────┤
│ TrainingCalendarView │ SSTDashboardView │ HealthSyncView    │
│ CalendarViewModel    │ ChartViewModel   │ HealthViewModel   │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                         Service Layer                       │
├─────────────────────────────────────────────────────────────┤
│ HealthKitService     │ FTPAnalysisService │ MetricsService  │
│ CalendarService      │ WHRCalculator      │ ExportService   │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                          Data Layer                         │
├─────────────────────────────────────────────────────────────┤
│ FTPHistory          │ DailyMetric        │ CyclingDetail   │
│ (New)               │ (New)              │ (Extended)       │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                       External APIs                         │
├─────────────────────────────────────────────────────────────┤
│              Apple HealthKit Framework                      │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 設計原則
1. **既存コード尊重**: 既存のWorkoutRecord、CyclingDetailを破壊しない拡張
2. **段階的実装**: Phase毎の独立デプロイ可能な設計
3. **性能重視**: 大量データでも高速描画可能なチャート設計
4. **プライバシー保護**: 健康データの適切な管理とユーザー同意

## 2. データモデル設計

### 2.1 新規モデル定義

#### 2.1.1 FTPHistory
```swift
import Foundation
import SwiftData

enum FTPMeasurementMethod: String, Codable, CaseIterable {
    case twentyMinuteTest = "20MinTest"
    case rampTest = "RampTest"
    case manual = "Manual"
    case autoCalculated = "AutoCalculated"
    
    var displayName: String {
        switch self {
        case .twentyMinuteTest: return "20分テスト"
        case .rampTest: return "ランプテスト"
        case .manual: return "手動入力"
        case .autoCalculated: return "自動計算"
        }
    }
}

@Model
final class FTPHistory {
    var id: UUID = UUID()
    var date: Date
    var ftpValue: Int                 // ワット
    var measurementMethod: FTPMeasurementMethod
    var notes: String?
    var isAutoCalculated: Bool
    var sourceWorkoutId: UUID?        // 元となったワークアウトのID
    
    init(date: Date = Date(), 
         ftpValue: Int, 
         measurementMethod: FTPMeasurementMethod = .manual, 
         notes: String? = nil, 
         isAutoCalculated: Bool = false,
         sourceWorkoutId: UUID? = nil) {
        self.date = date
        self.ftpValue = ftpValue
        self.measurementMethod = measurementMethod
        self.notes = notes
        self.isAutoCalculated = isAutoCalculated
        self.sourceWorkoutId = sourceWorkoutId
    }
}
```

#### 2.1.2 DailyMetric
```swift
import Foundation
import SwiftData

enum MetricDataSource: String, Codable {
    case manual = "Manual"
    case appleHealth = "AppleHealth"
    case calculated = "Calculated"
    
    var displayName: String {
        switch self {
        case .manual: return "手動入力"
        case .appleHealth: return "Apple Health"
        case .calculated: return "自動計算"
        }
    }
}

@Model
final class DailyMetric {
    var id: UUID = UUID()
    var date: Date
    var weightKg: Double?
    var restingHeartRate: Int?
    var maxHeartRate: Int?
    var dataSource: MetricDataSource
    var lastSyncDate: Date?
    
    init(date: Date = Date(),
         weightKg: Double? = nil,
         restingHeartRate: Int? = nil,
         maxHeartRate: Int? = nil,
         dataSource: MetricDataSource = .manual) {
        self.date = date
        self.weightKg = weightKg
        self.restingHeartRate = restingHeartRate
        self.maxHeartRate = maxHeartRate
        self.dataSource = dataSource
        self.lastSyncDate = dataSource == .appleHealth ? Date() : nil
    }
}
```

### 2.2 既存モデル拡張

#### 2.2.1 CyclingDetail拡張
```swift
// CyclingDetail.swift に追加するフィールド
extension CyclingDetail {
    var averageHeartRate: Int?       // 平均心拍数
    var maxHeartRate: Int?          // 最大心拍数  
    var maxPower: Double?           // 最大パワー
    var whrRatio: Double? {         // W/HR比（計算プロパティ）
        get {
            guard let avgHR = averageHeartRate, avgHR > 0 else { return nil }
            return averagePower / Double(avgHR)
        }
    }
    var normalizedPower: Double?    // 正規化パワー（NP）
    var intensityFactor: Double? {  // Intensity Factor (IF)
        get {
            guard let currentFTP = getCurrentFTP() else { return nil }
            return averagePower / Double(currentFTP)
        }
    }
    
    private func getCurrentFTP() -> Int? {
        // FTPHistoryから最新のFTPを取得するヘルパー関数
        // 実装は後述のFTPServiceで行う
        return nil
    }
}
```

## 3. サービス層設計

### 3.1 HealthKitService
```swift
import HealthKit
import Foundation

class HealthKitService: ObservableObject {
    private let healthStore = HKHealthStore()
    
    // 必要な権限
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .cyclingPower)!,
        HKObjectType.workoutType()
    ]
    
    // 主要メソッド
    func requestAuthorization() async throws
    func syncWeightData(from startDate: Date) async throws -> [DailyMetric]
    func syncWorkoutData(from startDate: Date) async throws -> [WorkoutRecord]
    func getLatestFTPFromWorkouts() async throws -> Int?
    func calculateTwentyMinutePower(for workout: HKWorkout) async throws -> Double?
}
```

### 3.2 FTPAnalysisService
```swift
import Foundation

class FTPAnalysisService {
    func suggestFTPUpdate(basedOn twentyMinPower: Double) -> Int {
        // 20分平均パワーの95%をFTPとして提案
        return Int(twentyMinPower * 0.95)
    }
    
    func calculateProgressTrend(history: [FTPHistory]) -> ProgressTrend {
        // FTP向上トレンドの計算
    }
    
    func generateFTPProjection(currentFTP: Int, trainingLoad: Double) -> Int {
        // 現在のトレーニング負荷に基づくFTP予測
    }
}

enum ProgressTrend {
    case improving(rate: Double)    // 向上率
    case stable                     // 安定
    case declining(rate: Double)    // 低下率
}
```

### 3.3 CalendarService
```swift
import Foundation

struct CalendarDay {
    let date: Date
    let workouts: [WorkoutRecord]
    let metrics: DailyMetric?
    let ftpUpdates: [FTPHistory]
    
    var hasActivities: Bool {
        return !workouts.isEmpty || metrics != nil || !ftpUpdates.isEmpty
    }
}

class CalendarService {
    func getMonthData(for date: Date) -> [CalendarDay] {
        // 指定月のカレンダーデータを生成
    }
    
    func getWeekData(for date: Date) -> [CalendarDay] {
        // 指定週のカレンダーデータを生成
    }
}
```

## 4. UI設計

### 4.1 トレーニングカレンダー

#### 4.1.1 TrainingCalendarView
```swift
struct TrainingCalendarView: View {
    @State private var selectedDate = Date()
    @State private var displayMode: CalendarDisplayMode = .month
    @State private var showingDayDetail = false
    @State private var selectedDay: CalendarDay?
    
    var body: some View {
        NavigationStack {
            VStack {
                // セグメントコントロール（月次/週次）
                Picker("表示", selection: $displayMode) {
                    Text("月").tag(CalendarDisplayMode.month)
                    Text("週").tag(CalendarDisplayMode.week)
                }
                .pickerStyle(SegmentedPickerStyle())
                
                // カレンダー本体
                if displayMode == .month {
                    MonthCalendarGrid(selectedDate: $selectedDate,
                                    onDayTap: { day in
                                        selectedDay = day
                                        showingDayDetail = true
                                    })
                } else {
                    WeekCalendarGrid(selectedDate: $selectedDate,
                                   onDayTap: { day in
                                       selectedDay = day
                                       showingDayDetail = true
                                   })
                }
            }
            .sheet(isPresented: $showingDayDetail) {
                if let day = selectedDay {
                    DayDetailView(day: day)
                }
            }
        }
    }
}

enum CalendarDisplayMode {
    case month, week
}
```

#### 4.1.2 DayDetailView
```swift
struct DayDetailView: View {
    let day: CalendarDay
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // 日付ヘッダー
                    Text(day.date.formatted(.dateTime.year().month().day().weekday()))
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    // ワークアウト一覧
                    if !day.workouts.isEmpty {
                        WorkoutSectionView(workouts: day.workouts)
                    }
                    
                    // メトリクス表示
                    if let metrics = day.metrics {
                        MetricsSectionView(metrics: metrics)
                    }
                    
                    // FTP更新
                    if !day.ftpUpdates.isEmpty {
                        FTPUpdateSectionView(updates: day.ftpUpdates)
                    }
                }
                .padding()
            }
            .navigationTitle("トレーニング詳細")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
```

### 4.2 SST進捗ダッシュボード

#### 4.2.1 SSTDashboardView
```swift
import SwiftUI
import Charts

struct SSTDashboardView: View {
    @StateObject private var viewModel = SSTDashboardViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 現在のFTP表示
                    CurrentFTPCard(currentFTP: viewModel.currentFTP,
                                  goalFTP: viewModel.goalFTP,
                                  progress: viewModel.ftpProgress)
                    
                    // FTP推移チャート
                    FTPProgressChart(history: viewModel.ftpHistory)
                    
                    // W/HR効率チャート
                    WHREfficiencyChart(whrData: viewModel.whrData)
                    
                    // 20分パワー目標
                    TwentyMinutePowerTarget(currentFTP: viewModel.currentFTP)
                }
                .padding()
            }
            .navigationTitle("SST進捗")
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}
```

#### 4.2.2 FTPProgressChart
```swift
struct FTPProgressChart: View {
    let history: [FTPHistory]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("FTP推移")
                .font(.headline)
                .padding(.bottom, 8)
            
            if history.isEmpty {
                ContentUnavailableView(
                    "FTP記録なし",
                    systemImage: "chart.bar.xaxis.ascending",
                    description: Text("FTPを記録して推移を確認しましょう")
                )
                .frame(height: 200)
            } else {
                Chart(history, id: \.id) { record in
                    LineMark(
                        x: .value("日付", record.date),
                        y: .value("FTP", record.ftpValue)
                    )
                    .foregroundStyle(.blue)
                    
                    PointMark(
                        x: .value("日付", record.date),
                        y: .value("FTP", record.ftpValue)
                    )
                    .foregroundStyle(.blue)
                    .symbol(.circle)
                }
                .frame(height: 200)
                .chartYScale(domain: .automatic)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
```

## 5. データフロー設計

### 5.1 Apple Health同期フロー
```
1. ユーザーがHealthKitアクセス許可
2. HealthKitServiceが定期的に新しいデータをチェック
3. 新しいワークアウトデータを検出
4. パワー・心拍数データを取得してCyclingDetailを拡張
5. 20分以上の高強度ワークアウトからFTP推定値を提案
6. UIに新しいデータとFTP提案を表示
```

### 5.2 FTP更新フロー
```
1. 20分以上のSST/VO2maxワークアウト完了
2. FTPAnalysisServiceが平均パワーを分析
3. 95%値を新FTPとして提案
4. ユーザーに確認ダイアログ表示
5. 承認されればFTPHistoryに新レコード追加
6. DashboardとChartのFTP値が自動更新
```

## 6. 性能設計

### 6.1 チャート描画最適化
- Swift Chartsの遅延描画機能を活用
- 大量データ時はデータ間引き（1日1ポイント等）
- メモリ使用量制限（最大365日分のデータのみメモリ保持）

### 6.2 データベースクエリ最適化
- 日付範囲でのインデックス活用
- 必要なフィールドのみのPartial Loading
- バックグラウンドでの前処理

## 7. エラーハンドリング設計

### 7.1 HealthKit接続エラー
- 権限拒否: 設定画面への誘導
- データ取得エラー: リトライ機構
- 異常値検出: ユーザーへの確認ダイアログ

### 7.2 データ整合性
- FTP値の妥当性チェック（50-500W範囲）
- 心拍数の妥当性チェック（60-220bpm範囲）
- 重複データの自動マージ

## 8. セキュリティ設計

### 8.1 プライバシー保護
- 健康データはデバイス内のみ保存
- CloudKit同期は今回スコープ外
- ユーザーの明示的同意なしでのデータアクセスは禁止

### 8.2 データアクセス制御
- HealthKitデータは最小権限の原則
- バックグラウンド同期は定期実行のみ
- ユーザーが同期を停止できる設定提供

## 9. テスト設計

### 9.1 ユニットテスト対象
- FTPAnalysisServiceの計算ロジック
- WHR計算の正確性
- データモデルのバリデーション

### 9.2 統合テスト対象
- HealthKit連携の動作確認
- チャート描画の性能テスト
- 大量データでのメモリ使用量テスト

## 10. 実装優先度

### Phase 1: データ基盤（High Priority）
1. FTPHistory, DailyMetricモデル作成
2. CyclingDetail拡張
3. 基本的なHealthKit連携

### Phase 2: 基本UI（Medium Priority）
1. トレーニングカレンダー基本機能
2. FTP推移チャート
3. データ入力フォーム

### Phase 3: 高度な機能（Low Priority）
1. W/HR効率分析
2. 自動FTP提案
3. エクスポート機能

この設計書に基づいて、要件書で定義された機能を段階的に実装していきます。