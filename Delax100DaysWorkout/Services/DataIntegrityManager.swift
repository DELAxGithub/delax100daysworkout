import Foundation
import SwiftData

@MainActor
class DataIntegrityManager: ObservableObject {
    @Published var lastValidationDate: Date?
    @Published var validationInProgress = false
    @Published var validationResults: [String: ValidationResult] = [:]
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func performFullValidation() async {
        validationInProgress = true
        validationResults.removeAll()
        
        await validateUserProfiles()
        await validateDailyLogs()
        await validateWorkoutRecords()
        await validateDailyMetrics()
        await validateFTPHistories()
        
        lastValidationDate = Date()
        validationInProgress = false
    }
    
    private func validateUserProfiles() async {
        do {
            let descriptor = FetchDescriptor<UserProfile>()
            let profiles = try modelContext.fetch(descriptor)
            
            var errors: [ValidationError] = []
            for profile in profiles {
                let result = profile.validate()
                if !result.isValid || !result.warnings.isEmpty {
                    errors.append(contentsOf: result.errors)
                    errors.append(contentsOf: result.warnings)
                }
            }
            
            validationResults["UserProfile"] = ValidationResult(errors: errors)
            
            if !errors.isEmpty {
                print("UserProfile validation issues: \(errors.count)")
            }
        } catch {
            print("Failed to validate UserProfiles: \(error)")
        }
    }
    
    private func validateDailyLogs() async {
        do {
            let descriptor = FetchDescriptor<DailyLog>()
            let logs = try modelContext.fetch(descriptor)
            
            var errors: [ValidationError] = []
            for log in logs {
                let result = log.validate()
                if !result.isValid || !result.warnings.isEmpty {
                    errors.append(contentsOf: result.errors)
                    errors.append(contentsOf: result.warnings)
                }
            }
            
            validationResults["DailyLog"] = ValidationResult(errors: errors)
            
            if !errors.isEmpty {
                print("DailyLog validation issues: \(errors.count)")
            }
        } catch {
            print("Failed to validate DailyLogs: \(error)")
        }
    }
    
    private func validateWorkoutRecords() async {
        do {
            let descriptor = FetchDescriptor<WorkoutRecord>()
            let records = try modelContext.fetch(descriptor)
            
            var errors: [ValidationError] = []
            for record in records {
                let result = record.validate()
                if !result.isValid || !result.warnings.isEmpty {
                    errors.append(contentsOf: result.errors)
                    errors.append(contentsOf: result.warnings)
                }
            }
            
            validationResults["WorkoutRecord"] = ValidationResult(errors: errors)
            
            if !errors.isEmpty {
                print("WorkoutRecord validation issues: \(errors.count)")
            }
        } catch {
            print("Failed to validate WorkoutRecords: \(error)")
        }
    }
    
    private func validateDailyMetrics() async {
        do {
            let descriptor = FetchDescriptor<DailyMetric>()
            let metrics = try modelContext.fetch(descriptor)
            
            var errors: [ValidationError] = []
            var duplicateDates: [String: [DailyMetric]] = [:]
            
            for metric in metrics {
                // 基本的な検証
                let result = metric.validate()
                if !result.isValid || !result.warnings.isEmpty {
                    errors.append(contentsOf: result.errors)
                    errors.append(contentsOf: result.warnings)
                }
                
                // 重複チェック
                let dateKey = metric.dateKey
                if duplicateDates[dateKey] == nil {
                    duplicateDates[dateKey] = []
                }
                duplicateDates[dateKey]?.append(metric)
            }
            
            // 重複データの報告
            for (date, metrics) in duplicateDates where metrics.count > 1 {
                errors.append(ValidationError(
                    field: "DailyMetric.date",
                    message: "\(date)に\(metrics.count)件の重複データがあります",
                    severity: .warning
                ))
            }
            
            validationResults["DailyMetric"] = ValidationResult(errors: errors)
            
            if !errors.isEmpty {
                print("DailyMetric validation issues: \(errors.count)")
            }
        } catch {
            print("Failed to validate DailyMetrics: \(error)")
        }
    }
    
    private func validateFTPHistories() async {
        do {
            let descriptor = FetchDescriptor<FTPHistory>(
                sortBy: [SortDescriptor(\FTPHistory.date, order: .forward)]
            )
            let histories = try modelContext.fetch(descriptor)
            
            var errors: [ValidationError] = []
            
            for (index, history) in histories.enumerated() {
                // 基本的な検証
                let result = history.validate()
                if !result.isValid || !result.warnings.isEmpty {
                    errors.append(contentsOf: result.errors)
                    errors.append(contentsOf: result.warnings)
                }
                
                // 時系列での急激な変化をチェック
                if index > 0 {
                    let previous = histories[index - 1]
                    let daysDiff = Calendar.current.dateComponents([.day], from: previous.date, to: history.date).day ?? 0
                    
                    if daysDiff > 0 && daysDiff < 7 {
                        let ftpChange = abs(Double(history.ftpValue - previous.ftpValue))
                        let changePercent = (ftpChange / Double(previous.ftpValue)) * 100
                        
                        if changePercent > 10 {
                            errors.append(ValidationError(
                                field: "FTPHistory.ftpValue",
                                message: "\(daysDiff)日間でFTPが\(Int(changePercent))%変化しています",
                                severity: .warning
                            ))
                        }
                    }
                }
            }
            
            validationResults["FTPHistory"] = ValidationResult(errors: errors)
            
            if !errors.isEmpty {
                print("FTPHistory validation issues: \(errors.count)")
            }
        } catch {
            print("Failed to validate FTPHistories: \(error)")
        }
    }
    
    func checkDataIntegrity() -> DataIntegrityReport {
        var report = DataIntegrityReport()
        
        do {
            // ワークアウトレコードと詳細データの整合性チェック
            let workoutDescriptor = FetchDescriptor<WorkoutRecord>()
            let workouts = try modelContext.fetch(workoutDescriptor)
            
            for workout in workouts {
                switch workout.workoutType {
                case .cycling:
                    if workout.cyclingDetail == nil && workout.isCompleted {
                        report.orphanedRecords.append("Cycling workout without details: \(workout.date)")
                    }
                case .strength:
                    if (workout.strengthDetails == nil || workout.strengthDetails?.isEmpty == true) && workout.isCompleted {
                        report.orphanedRecords.append("Strength workout without details: \(workout.date)")
                    }
                case .flexibility:
                    if workout.flexibilityDetail == nil && workout.isCompleted {
                        report.orphanedRecords.append("Flexibility workout without details: \(workout.date)")
                    }
                }
            }
            
            // データ量の統計
            report.totalRecords["UserProfile"] = try modelContext.fetchCount(FetchDescriptor<UserProfile>())
            report.totalRecords["DailyLog"] = try modelContext.fetchCount(FetchDescriptor<DailyLog>())
            report.totalRecords["WorkoutRecord"] = try modelContext.fetchCount(FetchDescriptor<WorkoutRecord>())
            report.totalRecords["DailyMetric"] = try modelContext.fetchCount(FetchDescriptor<DailyMetric>())
            report.totalRecords["FTPHistory"] = try modelContext.fetchCount(FetchDescriptor<FTPHistory>())
            
        } catch {
            print("Failed to check data integrity: \(error)")
        }
        
        return report
    }
    
    func repairDuplicateDailyMetrics() async throws {
        let descriptor = FetchDescriptor<DailyMetric>(
            sortBy: [SortDescriptor(\DailyMetric.date, order: .forward)]
        )
        let metrics = try modelContext.fetch(descriptor)
        
        var dateGroups: [String: [DailyMetric]] = [:]
        
        // 日付ごとにグループ化
        for metric in metrics {
            let dateKey = metric.dateKey
            if dateGroups[dateKey] == nil {
                dateGroups[dateKey] = []
            }
            dateGroups[dateKey]?.append(metric)
        }
        
        // 重複をマージ
        for (_, metricsForDate) in dateGroups where metricsForDate.count > 1 {
            // 最初のメトリクスをベースにマージ
            let baseMetric = metricsForDate[0]
            
            for i in 1..<metricsForDate.count {
                let duplicateMetric = metricsForDate[i]
                let merged = baseMetric.mergeWith(duplicateMetric)
                
                // ベースメトリクスを更新
                baseMetric.weightKg = merged.weightKg
                baseMetric.restingHeartRate = merged.restingHeartRate
                baseMetric.maxHeartRate = merged.maxHeartRate
                baseMetric.dataSource = merged.dataSource
                baseMetric.lastSyncDate = merged.lastSyncDate
                baseMetric.updatedAt = Date()
                
                // 重複を削除
                modelContext.delete(duplicateMetric)
            }
        }
        
        try modelContext.save()
    }
    
    func validateBeforeSave<T: ModelValidation>(_ model: T) throws {
        let result = model.validate()
        
        if !result.isValid {
            let errorMessages = result.errors.map { $0.message }.joined(separator: ", ")
            throw ValidationError.saveFailed(reason: errorMessages)
        }
    }
}

struct DataIntegrityReport {
    var orphanedRecords: [String] = []
    var totalRecords: [String: Int] = [:]
    var validationErrors: [String: [ValidationError]] = [:]
    
    var hasIssues: Bool {
        !orphanedRecords.isEmpty || !validationErrors.isEmpty
    }
    
    var summary: String {
        var lines: [String] = []
        
        lines.append("=== データ整合性レポート ===")
        
        if !orphanedRecords.isEmpty {
            lines.append("\n孤立レコード: \(orphanedRecords.count)件")
            for record in orphanedRecords.prefix(5) {
                lines.append("  - \(record)")
            }
        }
        
        if !validationErrors.isEmpty {
            lines.append("\n検証エラー:")
            for (model, errors) in validationErrors {
                lines.append("  \(model): \(errors.count)件")
            }
        }
        
        lines.append("\n総レコード数:")
        for (model, count) in totalRecords {
            lines.append("  \(model): \(count)件")
        }
        
        return lines.joined(separator: "\n")
    }
}

enum ValidationError: Error {
    case saveFailed(reason: String)
    
    var localizedDescription: String {
        switch self {
        case .saveFailed(let reason):
            return "保存失敗: \(reason)"
        }
    }
}