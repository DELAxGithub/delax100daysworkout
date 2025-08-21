# HealthKit導入手引書

## 概要

HealthKitは、Appleが提供するiOS向けヘルスケアフレームワークです。アプリ間でヘルスデータを安全に共有し、ユーザーの健康情報を統合管理できます。

## 1. プロジェクト設定

### 1.1 Capabilityの追加

1. Xcodeでプロジェクトを開く
2. プロジェクト設定の「Signing & Capabilities」タブを選択
3. 「+ Capability」ボタンをクリック
4. 「HealthKit」を検索して追加

### 1.2 Info.plistの設定

```xml
<key>NSHealthShareUsageDescription</key>
<string>このアプリは体重や運動データを読み取り、健康管理機能を提供します</string>
<key>NSHealthUpdateUsageDescription</key>
<string>このアプリは体重や運動データを記録し、健康情報を更新します</string>
```

## 2. 基本実装

### 2.1 HealthKitManagerの作成

```swift
import HealthKit

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    
    // 読み取り権限が必要なデータタイプ
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!
    ]
    
    // 書き込み権限が必要なデータタイプ
    private let writeTypes: Set<HKSampleType> = [
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
    ]
    
    // HealthKitが利用可能かチェック
    var isHealthKitAvailable: Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    // 権限リクエスト
    func requestPermissions() async throws {
        guard isHealthKitAvailable else {
            throw HealthKitError.notAvailable
        }
        
        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
    }
}

enum HealthKitError: Error {
    case notAvailable
    case unauthorized
    case noData
}
```

### 2.2 データの読み取り

```swift
extension HealthKitManager {
    // 最新の体重を取得
    func getLatestWeight() async throws -> Double? {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return nil
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(
            sampleType: weightType,
            predicate: nil,
            limit: 1,
            sortDescriptors: [sortDescriptor]
        ) { _, samples, error in
            // クロージャ内でのエラーハンドリング
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let weightInKg = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
                continuation.resume(returning: weightInKg)
            }
            
            healthStore.execute(query)
        }
    }
    
    // 指定期間の歩数を取得
    func getStepCount(from startDate: Date, to endDate: Date) async throws -> Double {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.noData
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let stepCount = result?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: stepCount)
            }
            
            healthStore.execute(query)
        }
    }
}
```

### 2.3 データの書き込み

```swift
extension HealthKitManager {
    // 体重データを保存
    func saveWeight(_ weight: Double, date: Date = Date()) async throws {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.noData
        }
        
        let weightQuantity = HKQuantity(unit: HKUnit.gramUnit(with: .kilo), doubleValue: weight)
        let weightSample = HKQuantitySample(
            type: weightType,
            quantity: weightQuantity,
            start: date,
            end: date
        )
        
        try await healthStore.save(weightSample)
    }
    
    // 消費カロリーを保存
    func saveActiveEnergy(_ calories: Double, date: Date = Date()) async throws {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.noData
        }
        
        let energyQuantity = HKQuantity(unit: HKUnit.kilocalorie(), doubleValue: calories)
        let energySample = HKQuantitySample(
            type: energyType,
            quantity: energyQuantity,
            start: date,
            end: date
        )
        
        try await healthStore.save(energySample)
    }
}
```

## 3. SwiftUIでの使用

### 3.1 環境設定

```swift
@main
struct MyHealthApp: App {
    @StateObject private var healthKitManager = HealthKitManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthKitManager)
        }
    }
}
```

### 3.2 ビューでの実装

```swift
struct HealthDataView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var currentWeight: Double?
    @State private var todaySteps: Double = 0
    @State private var showingPermissionAlert = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("健康データ")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Group {
                if let weight = currentWeight {
                    Text("体重: \(weight, specifier: "%.1f") kg")
                } else {
                    Text("体重: データなし")
                }
                
                Text("今日の歩数: \(Int(todaySteps)) 歩")
            }
            .font(.title2)
            
            Button("データを更新") {
                Task {
                    await loadHealthData()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .task {
            await requestPermissionsIfNeeded()
            await loadHealthData()
        }
        .alert("HealthKitへのアクセス", isPresented: $showingPermissionAlert) {
            Button("設定") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("健康データにアクセスするには、設定でHealthKitの権限を有効にしてください。")
        }
    }
    
    private func requestPermissionsIfNeeded() async {
        do {
            try await healthKitManager.requestPermissions()
        } catch {
            await MainActor.run {
                showingPermissionAlert = true
            }
        }
    }
    
    private func loadHealthData() async {
        do {
            // 体重データを取得
            let weight = try await healthKitManager.getLatestWeight()
            
            // 今日の歩数を取得
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: Date())
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            let steps = try await healthKitManager.getStepCount(from: startOfDay, to: endOfDay)
            
            await MainActor.run {
                currentWeight = weight
                todaySteps = steps
            }
        } catch {
            print("HealthKitデータの取得に失敗: \(error)")
        }
    }
}
```

## 4. バックグラウンド更新の実装

### 4.1 バックグラウンド配信の設定

```swift
extension HealthKitManager {
    func enableBackgroundDelivery() async throws {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return
        }
        
        try await healthStore.enableBackgroundDelivery(
            for: weightType,
            frequency: .immediate
        ) { [weak self] query, error in
            if let error = error {
                print("バックグラウンド配信エラー: \(error)")
                return
            }
            
            Task {
                await self?.handleBackgroundUpdate()
            }
        }
    }
    
    private func handleBackgroundUpdate() async {
        // バックグラウンドでデータが更新された時の処理
        print("HealthKitデータが更新されました")
        
        // 必要に応じてアプリのデータを更新
        NotificationCenter.default.post(name: .healthDataUpdated, object: nil)
    }
}

extension Notification.Name {
    static let healthDataUpdated = Notification.Name("healthDataUpdated")
}
```

## 5. エラーハンドリングとベストプラクティス

### 5.1 権限の確認

```swift
extension HealthKitManager {
    func checkAuthorizationStatus(for type: HKObjectType) -> HKAuthorizationStatus {
        return healthStore.authorizationStatus(for: type)
    }
    
    var isWeightAuthorized: Bool {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return false
        }
        return checkAuthorizationStatus(for: weightType) == .sharingAuthorized
    }
}
```

### 5.2 データの検証

```swift
extension HealthKitManager {
    func saveWeightWithValidation(_ weight: Double) async throws {
        // データの妥当性チェック
        guard weight > 0 && weight < 1000 else {
            throw HealthKitError.invalidData
        }
        
        try await saveWeight(weight)
    }
}

extension HealthKitError {
    static let invalidData = HealthKitError.noData // 適切なエラータイプを定義
}
```

## 6. テスト方法

### 6.1 シミュレーターでのテスト

1. iOS シミュレーターを起動
2. 「設定」アプリ → 「プライバシーとセキュリティ」 → 「ヘルスケア」
3. テストデータを手動で入力してアプリの動作を確認

### 6.2 実機でのテスト

1. 実機にアプリをインストール
2. 「ヘルスケア」アプリでサンプルデータを作成
3. アプリの権限設定を確認
4. データの読み書きをテスト

## 7. リリース時の注意点

### 7.1 App Store審査

- HealthKitを使用する場合、App Storeの審査で健康関連の機能について詳細に確認される
- プライバシーポリシーにHealthKitの使用について明記する必要がある
- 医療アドバイスを提供しないことを明確にする

### 7.2 プライバシー設定

```xml
<!-- Info.plist -->
<key>NSHealthShareUsageDescription</key>
<string>このアプリは体重や活動データを読み取り、健康管理機能を提供します。データは端末上で安全に管理され、第三者と共有されることはありません。</string>

<key>NSHealthUpdateUsageDescription</key>
<string>このアプリは健康データを記録し、ヘルスケアアプリと同期します。記録されたデータはAppleのヘルスケアアプリで管理できます。</string>
```

## まとめ

この手引書に従って実装することで、HealthKitを活用した健康管理アプリを開発できます。ユーザーのプライバシーを最優先に考慮し、適切な権限管理とエラーハンドリングを実装することが重要です。

実装時は段階的に機能を追加し、各段階でしっかりとテストを行うことをお勧めします。