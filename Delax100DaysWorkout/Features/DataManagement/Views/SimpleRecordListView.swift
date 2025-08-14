import SwiftUI
import SwiftData

// MARK: - Simple Record List View

struct SimpleRecordListView: View {
    let modelType: EditableModel
    let modelContext: ModelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedRecord: Any?
    
    var body: some View {
        List {
            switch modelType {
            case .ftpHistory:
                let records = (try? modelContext.fetch(FetchDescriptor<FTPHistory>())) ?? []
                ForEach(records, id: \.id) { record in
                    NavigationLink(destination: FTPEditSheet(ftpRecord: record)) {
                        VStack(alignment: .leading) {
                            Text("\(record.ftpValue) W")
                            Text(record.formattedDate).font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(records[index])
                    }
                    try? modelContext.save()
                }
            case .dailyMetrics:
                let records = (try? modelContext.fetch(FetchDescriptor<DailyMetric>())) ?? []
                ForEach(records.filter { $0.hasAnyData }, id: \.id) { record in
                    VStack(alignment: .leading) {
                        Text(record.formattedWeight ?? "No weight")
                        Text(record.formattedDate).font(.caption).foregroundColor(.secondary)
                    }
                }
                .onDelete { indexSet in
                    let validRecords = records.filter { $0.hasAnyData }
                    for index in indexSet {
                        modelContext.delete(validRecords[index])
                    }
                    try? modelContext.save()
                }
            case .workoutRecords:
                let records = (try? modelContext.fetch(FetchDescriptor<WorkoutRecord>())) ?? []
                ForEach(records, id: \.id) { record in
                    VStack(alignment: .leading) {
                        Text(record.summary)
                        Text(record.workoutType.rawValue).font(.caption).foregroundColor(.secondary)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(records[index])
                    }
                    try? modelContext.save()
                }
            case .dailyTasks:
                let records = (try? modelContext.fetch(FetchDescriptor<DailyTask>())) ?? []
                ForEach(records, id: \.id) { record in
                    VStack(alignment: .leading) {
                        Text(record.title)
                        Text(record.dayName).font(.caption).foregroundColor(.secondary)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(records[index])
                    }
                    try? modelContext.save()
                }
            case .weeklyTemplates:
                let records = (try? modelContext.fetch(FetchDescriptor<WeeklyTemplate>())) ?? []
                ForEach(records, id: \.id) { record in
                    VStack(alignment: .leading) {
                        Text(record.name)
                        Text("\(record.dailyTasks.count) tasks").font(.caption).foregroundColor(.secondary)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(records[index])
                    }
                    try? modelContext.save()
                }
            case .userProfiles:
                let records = (try? modelContext.fetch(FetchDescriptor<UserProfile>())) ?? []
                ForEach(records, id: \.id) { record in
                    VStack(alignment: .leading) {
                        Text("Profile")
                        Text("Goal: \(record.goalWeightKg)kg").font(.caption).foregroundColor(.secondary)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        modelContext.delete(records[index])
                    }
                    try? modelContext.save()
                }
            }
        }
        .navigationTitle(modelType.displayName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("閉じる") { dismiss() }
            }
        }
    }
}