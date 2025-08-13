import SwiftUI
import SwiftData

struct WorkoutRecordFormView: View {
    enum Mode {
        case create
        case edit(WorkoutRecord)
    }
    
    let mode: Mode
    let onSave: (WorkoutRecord) -> Void
    let onCancel: () -> Void
    
    @State private var date = Date()
    @State private var workoutType: WorkoutType = .cycling
    @State private var summary = ""
    @State private var isCompleted = false
    @State private var isQuickRecord = false
    
    @State private var validationErrors: [String] = []
    
    var body: some View {
        NavigationView {
            Form {
                Section("Workout Details") {
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Workout Type", selection: $workoutType) {
                        ForEach(WorkoutType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.iconName)
                                .foregroundColor(type.iconColor)
                                .tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    VStack(alignment: .leading) {
                        Text("Summary")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Enter workout summary", text: $summary, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Toggle("Completed", isOn: $isCompleted)
                    Toggle("Quick Record", isOn: $isQuickRecord)
                }
                
                if !validationErrors.isEmpty {
                    Section("Validation Errors") {
                        ForEach(validationErrors, id: \.self) { error in
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
                
                Section {
                    HStack {
                        Button("Cancel", action: onCancel)
                            .foregroundColor(.red)
                        
                        Spacer()
                        
                        Button("Save") {
                            if validateForm() {
                                saveRecord()
                            }
                        }
                        .fontWeight(.semibold)
                        .disabled(!isFormValid)
                    }
                }
            }
            .navigationTitle(isEditMode ? "Edit Workout" : "New Workout")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            if case .edit(let record) = mode {
                populateFromRecord(record)
            }
        }
    }
    
    private var isEditMode: Bool {
        if case .edit = mode { return true }
        return false
    }
    
    private var isFormValid: Bool {
        !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func populateFromRecord(_ record: WorkoutRecord) {
        date = record.date
        workoutType = record.workoutType
        summary = record.summary
        isCompleted = record.isCompleted
        isQuickRecord = record.isQuickRecord
    }
    
    private func validateForm() -> Bool {
        validationErrors.removeAll()
        
        if summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Summary is required")
        }
        
        if summary.count > 500 {
            validationErrors.append("Summary must be less than 500 characters")
        }
        
        if date > Date().addingTimeInterval(24 * 60 * 60) {
            validationErrors.append("Workout date cannot be more than 24 hours in the future")
        }
        
        return validationErrors.isEmpty
    }
    
    private func saveRecord() {
        let record: WorkoutRecord
        
        if case .edit(let existingRecord) = mode {
            record = existingRecord
            record.date = date
            record.workoutType = workoutType
            record.summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
            record.isCompleted = isCompleted
            record.isQuickRecord = isQuickRecord
        } else {
            record = WorkoutRecord(
                date: date,
                workoutType: workoutType,
                summary: summary.trimmingCharacters(in: .whitespacesAndNewlines),
                isQuickRecord: isQuickRecord
            )
            record.isCompleted = isCompleted
        }
        
        onSave(record)
    }
}

struct WorkoutRecordDetailView: View {
    let record: WorkoutRecord
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header Card
                    headerCard
                    
                    // Basic Details
                    detailsCard
                    
                    // Workout Type Specific Details
                    if let cyclingDetail = record.cyclingDetail {
                        CyclingDetailCard(detail: cyclingDetail)
                    }
                    
                    // Additional sections for other workout types
                    // TODO: Add strength, flexibility, pilates, yoga detail cards
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Workout Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 12) {
            HStack {
                Label("", systemImage: record.workoutType.iconName)
                    .foregroundColor(record.workoutType.iconColor)
                    .font(.largeTitle)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(record.isCompleted ? "Completed" : "Pending")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(record.isCompleted ? .green : .orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(record.isCompleted ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        )
                    
                    if record.isQuickRecord {
                        Text("Quick Record")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(record.workoutType.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(record.summary)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                DetailRow(label: "Date", value: record.date.formatted(date: .complete, time: .shortened))
                DetailRow(label: "Type", value: record.workoutType.rawValue)
                DetailRow(label: "Status", value: record.isCompleted ? "Completed" : "Pending")
                
                if record.isQuickRecord {
                    DetailRow(label: "Quick Record", value: "Yes")
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

struct CyclingDetailCard: View {
    let detail: CyclingDetail
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cycling Details")
                .font(.headline)
                .fontWeight(.bold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                MetricCard(title: "Distance", value: detail.formattedDistance, icon: "road.lanes")
                MetricCard(title: "Duration", value: detail.formattedDuration, icon: "clock")
                MetricCard(title: "Avg Power", value: detail.formattedAveragePower, icon: "bolt")
                MetricCard(title: "Intensity", value: detail.intensity.description, icon: "speedometer")
                
                if let avgHR = detail.formattedAverageHeartRate {
                    MetricCard(title: "Avg HR", value: avgHR, icon: "heart")
                }
                
                if let maxPower = detail.formattedMaxPower {
                    MetricCard(title: "Max Power", value: maxPower, icon: "bolt.fill")
                }
            }
            
            if let notes = detail.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(8)
    }
}