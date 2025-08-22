import SwiftUI
import HealthKit
import OSLog

// Reference Guide Implementation: HealthDataView
// この画面は手引書通りの実装を提供し、HealthKitの基本機能をテスト・デモできます
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
            
            // データ書き込みテスト用のボタン
            VStack(spacing: 12) {
                Button("テスト: 体重データを保存") {
                    Task {
                        await saveTestWeight()
                    }
                }
                .buttonStyle(.bordered)
                
                Button("テスト: 消費カロリーを保存") {
                    Task {
                        await saveTestCalories()
                    }
                }
                .buttonStyle(.bordered)
                
                Button("テスト: 基礎代謝を保存") {
                    Task {
                        await saveTestBasalEnergy()
                    }
                }
                .buttonStyle(.bordered)
                
                Button("テスト: 心拍数を保存") {
                    Task {
                        await saveTestHeartRate()
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding(.top)
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
            Logger.error.error("HealthKitデータの取得に失敗: \(error.localizedDescription)")
        }
    }
    
    // テスト用のデータ保存メソッド
    private func saveTestWeight() async {
        do {
            let testWeight = 70.5 // テスト用の体重データ
            try await healthKitManager.saveWeight(testWeight)
            Logger.debug.debug("テスト体重データを保存しました: \(testWeight, privacy: .public)kg")
            
            // データを再読み込み
            await loadHealthData()
        } catch {
            Logger.error.error("体重データの保存に失敗: \(error.localizedDescription)")
        }
    }
    
    private func saveTestCalories() async {
        do {
            let testCalories = 250.0 // テスト用の消費カロリー
            try await healthKitManager.saveActiveEnergy(testCalories)
            Logger.debug.debug("テスト消費カロリーを保存しました: \(testCalories, privacy: .public)kcal")
        } catch {
            Logger.error.error("消費カロリーの保存に失敗: \(error.localizedDescription)")
        }
    }
    
    private func saveTestBasalEnergy() async {
        do {
            let testBasalCalories = 1500.0 // テスト用の基礎代謝
            try await healthKitManager.saveBasalEnergy(testBasalCalories)
            Logger.debug.debug("テスト基礎代謝を保存しました: \(testBasalCalories, privacy: .public)kcal")
        } catch {
            Logger.error.error("基礎代謝の保存に失敗: \(error.localizedDescription)")
        }
    }
    
    private func saveTestHeartRate() async {
        do {
            let testHeartRate = 75 // テスト用の心拍数
            try await healthKitManager.saveHeartRate(testHeartRate)
            Logger.debug.debug("テスト心拍数を保存しました: \(testHeartRate, privacy: .public)bpm")
        } catch {
            Logger.error.error("心拍数の保存に失敗: \(error.localizedDescription)")
        }
    }
}

#Preview {
    NavigationView {
        HealthDataView()
            .navigationTitle("HealthKit テスト")
    }
    .environmentObject(HealthKitManager.shared)
}