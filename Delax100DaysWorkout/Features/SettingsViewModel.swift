import Foundation
import SwiftData

@Observable
class SettingsViewModel {
    var goalDate: Date = Date().addingTimeInterval(100 * 24 * 60 * 60)
    var startWeightKg: Double = 0.0
    var goalWeightKg: Double = 0.0
    var startFtp: Int = 0
    var goalFtp: Int = 0

    var showSaveConfirmation = false

    private var modelContext: ModelContext
    private var userProfile: UserProfile?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchOrCreateUserProfile()
    }

    private func fetchOrCreateUserProfile() {
        let descriptor = FetchDescriptor<UserProfile>()
        do {
            if let profile = try modelContext.fetch(descriptor).first {
                // 既存のプロフィールを読み込む
                self.userProfile = profile
                self.goalDate = profile.goalDate
                self.startWeightKg = profile.startWeightKg
                self.goalWeightKg = profile.goalWeightKg
                self.startFtp = profile.startFtp
                self.goalFtp = profile.goalFtp
            } else {
                // プロフィールが存在しない場合、新しいデフォルトプロフィールを作成して保存
                let newProfile = UserProfile()
                modelContext.insert(newProfile)
                self.userProfile = newProfile
            }
        } catch {
            print("Failed to fetch UserProfile: \(error)")
        }
    }

    func save() {
        guard let userProfile = userProfile else { return }

        // ViewModelの値をモデルに反映
        userProfile.goalDate = self.goalDate
        userProfile.startWeightKg = self.startWeightKg
        userProfile.goalWeightKg = self.goalWeightKg
        userProfile.startFtp = self.startFtp
        userProfile.goalFtp = self.goalFtp

        // Show confirmation alert
        showSaveConfirmation = true
    }
}