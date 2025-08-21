import SwiftUI
import HealthKit

// ヘルスケア設定セクション
struct HealthcareSection: View {
    var viewModel: SettingsViewModel
    @State private var showingDetailedStatus = false
    
    // モーダル排他制御用の計算プロパティ
    private var canShowModal: Bool {
        !viewModel.showSaveError && !viewModel.showSaveConfirmation
    }
    
    var body: some View {
        Section {
            // HealthKit認証状態
            HStack {
                Label("Apple Health連携", systemImage: "heart.fill")
                    .foregroundColor(.red)
                
                Spacer()
                
                Text(viewModel.healthKitAuthStatus)
                    .foregroundColor(viewModel.healthKitManager.isAuthorized ? .green : .orange)
                    .fontWeight(.medium)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if canShowModal {
                    showingDetailedStatus = true
                }
            }
            
            // 最終同期日時
            if viewModel.healthKitManager.isAuthorized {
                HStack {
                    Text("最終同期")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(viewModel.lastHealthKitSyncDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 手動同期ボタン
            if viewModel.healthKitManager.isAuthorized {
                Button(action: {
                    Task {
                        await viewModel.syncHealthKitData()
                    }
                }) {
                    HStack {
                        if viewModel.isHealthKitSyncing {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        
                        Text("データ同期")
                    }
                }
                .disabled(viewModel.isHealthKitSyncing)
            } else {
                // 認証要求ボタン
                Button(action: {
                    Task {
                        await viewModel.requestHealthKitAuthorization()
                    }
                }) {
                    Text(viewModel.healthKitManager.isAuthorized ? "認証状態を再確認" : "Apple Healthを連携")
                        .foregroundColor(.blue)
                }
            }
        } header: {
            Text("ヘルスケア")
        } footer: {
            Text("体重、心拍数、ワークアウトデータをApple Healthから自動で取得します。")
        }
        .sheet(isPresented: Binding<Bool>(
            get: { showingDetailedStatus && canShowModal },
            set: { newValue in
                if !newValue || canShowModal {
                    showingDetailedStatus = newValue
                }
            }
        )) {
            HealthKitDetailedStatusSheet(
                authInfo: createAuthInfo()
            )
        }
    }
    
    private func createAuthInfo() -> HealthKitAuthorizationInfo {
        var typeStatuses: [HKObjectType: HKAuthorizationStatus] = [:]
        
        // 各データタイプの認証状況を取得
        if let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            typeStatuses[bodyMassType] = viewModel.healthKitManager.checkAuthorizationStatus(for: bodyMassType)
        }
        if let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) {
            typeStatuses[heartRateType] = viewModel.healthKitManager.checkAuthorizationStatus(for: heartRateType)
        }
        if let cyclingPowerType = HKObjectType.quantityType(forIdentifier: .cyclingPower) {
            typeStatuses[cyclingPowerType] = viewModel.healthKitManager.checkAuthorizationStatus(for: cyclingPowerType)
        }
        if let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            typeStatuses[activeEnergyType] = viewModel.healthKitManager.checkAuthorizationStatus(for: activeEnergyType)
        }
        let workoutType = HKObjectType.workoutType()
        typeStatuses[workoutType] = viewModel.healthKitManager.checkAuthorizationStatus(for: workoutType)
        
        return HealthKitAuthorizationInfo(
            overallStatus: viewModel.healthKitManager.authorizationStatus,
            typeStatuses: typeStatuses,
            healthDataAvailable: HKHealthStore.isHealthDataAvailable()
        )
    }
}

#Preview {
    NavigationView {
        Form {
            Section("ヘルスケア") {
                Text("Preview not available")
            }
        }
        .navigationTitle("設定")
    }
}