import SwiftUI
import HealthKit

struct HealthKitDetailedStatusSheet: View {
    let authInfo: HealthKitAuthorizationInfo
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Overall status section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("全体の状況")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        HStack {
                            Image(systemName: statusIcon(authInfo.overallStatus))
                                .foregroundColor(statusColor(authInfo.overallStatus))
                                .font(.title2)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Apple Health連携")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(statusDescription(authInfo.overallStatus))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color(UIColor.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Individual data types section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("データ別の許可状況")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 8) {
                            DataTypeStatusRow(
                                title: "体重データ",
                                description: "進捗追跡と目標管理に使用",
                                status: authInfo.bodyMassStatus
                            )
                            
                            DataTypeStatusRow(
                                title: "心拍数データ",
                                description: "コンディション分析と回復指標",
                                status: authInfo.heartRateStatus
                            )
                            
                            DataTypeStatusRow(
                                title: "サイクリングパワー",
                                description: "FTP分析とパフォーマンス測定",
                                status: authInfo.cyclingPowerStatus
                            )
                            
                            DataTypeStatusRow(
                                title: "ワークアウトデータ",
                                description: "トレーニング履歴と統計",
                                status: authInfo.workoutStatus
                            )
                        }
                    }
                    
                    // User guidance section
                    if authInfo.overallStatus == .sharingDenied {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("設定方法")
                                .font(.headline)
                                .fontWeight(.bold)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("1. この画面下の「ヘルスアプリを開く」をタップ")
                                Text("2. ヘルスアプリで「共有」タブを選択")
                                Text("3. 「\(Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? "このアプリ")」をタップ")
                                Text("4. 必要なデータタイプをオンにする")
                                Text("5. アプリに戻って「再試行」をタップ")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            
                            VStack(spacing: 8) {
                                Button("ヘルスアプリを開く") {
                                    openHealthApp()
                                }
                                .buttonStyle(.borderedProminent)
                                
                                Button("再試行") {
                                    Task {
                                        do {
                                            try await HealthKitManager.shared.requestPermissions()
                                        } catch {
                                            // Error will be logged by HealthKitManager
                                        }
                                    }
                                    dismiss()
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding()
                        .background(Color(UIColor.systemBlue).opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("ヘルスケア連携詳細")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }
    
    private func statusIcon(_ status: HKAuthorizationStatus) -> String {
        switch status {
        case .sharingAuthorized:
            return "checkmark.circle.fill"
        case .sharingDenied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        @unknown default:
            return "exclamationmark.circle.fill"
        }
    }
    
    private func statusColor(_ status: HKAuthorizationStatus) -> Color {
        switch status {
        case .sharingAuthorized:
            return .green
        case .sharingDenied:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .secondary
        }
    }
    
    private func statusDescription(_ status: HKAuthorizationStatus) -> String {
        switch status {
        case .sharingAuthorized:
            return "アクセス許可済み"
        case .sharingDenied:
            return "アクセス拒否"
        case .notDetermined:
            return "未設定"
        @unknown default:
            return "状態不明"
        }
    }
    
    private func openHealthApp() {
        // Try to open Health app directly first
        if let healthAppUrl = URL(string: "x-apple-health://"),
           UIApplication.shared.canOpenURL(healthAppUrl) {
            UIApplication.shared.open(healthAppUrl)
        } else {
            // Fallback to Settings app if Health app URL doesn't work
            openSettingsApp()
        }
    }
    
    private func openSettingsApp() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }
        UIApplication.shared.open(settingsUrl)
    }
}

struct DataTypeStatusRow: View {
    let title: String
    let description: String
    let status: HKAuthorizationStatus
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 6) {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(statusColor)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
    
    private var statusIcon: String {
        switch status {
        case .sharingAuthorized:
            return "checkmark.circle.fill"
        case .sharingDenied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        @unknown default:
            return "exclamationmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .sharingAuthorized:
            return .green
        case .sharingDenied:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .secondary
        }
    }
    
    private var statusText: String {
        switch status {
        case .sharingAuthorized:
            return "許可"
        case .sharingDenied:
            return "拒否"
        case .notDetermined:
            return "未設定"
        @unknown default:
            return "不明"
        }
    }
}