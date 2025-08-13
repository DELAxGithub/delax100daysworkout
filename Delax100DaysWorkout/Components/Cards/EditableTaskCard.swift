import SwiftUI
import SwiftData

// MARK: - Editable Task Card Component

struct EditableTaskCard: View {
    @Bindable var task: DailyTask
    let viewModel: WeeklyScheduleViewModel
    
    @State private var editingTitle: String = ""
    @State private var editingDescription: String = ""
    @State private var isEditing: Bool = false
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    private var animationValue: Animation? {
        reduceMotion ? .none : .spring(response: 0.3, dampingFraction: 0.7)
    }
    
    private var workoutColor: Color {
        switch task.workoutType {
        case .cycling: return .blue
        case .strength: return .orange
        case .flexibility: return .green
        case .pilates: return .purple
        case .yoga: return .mint
        }
    }
    
    var body: some View {
        BaseCard {
            VStack(alignment: .leading, spacing: Spacing.md.value) {
                // Header with edit controls
                HStack {
                    if isEditing {
                        VStack(alignment: .leading, spacing: Spacing.sm.value) {
                            // Title editing
                            TextField("タスク名", text: $editingTitle)
                                .textFieldStyle(.roundedBorder)
                                .focused($isTextFieldFocused)
                                .font(Typography.bodyMedium.font)
                                .onSubmit {
                                    saveChanges()
                                }
                            
                            // Description editing
                            TextField("説明（オプション）", text: $editingDescription)
                                .textFieldStyle(.roundedBorder)
                                .font(Typography.captionMedium.font)
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(Typography.headlineMedium.font)
                                .foregroundColor(SemanticColor.primaryText.color)
                                .onTapGesture(count: 2) {
                                    startEditing()
                                }
                            
                            if let description = task.taskDescription, !description.isEmpty {
                                Text(description)
                                    .font(Typography.captionMedium.font)
                                    .foregroundColor(SemanticColor.secondaryText.color)
                                    .onTapGesture(count: 2) {
                                        startEditing()
                                    }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Edit controls
                    if isEditing {
                        HStack(spacing: Spacing.sm.value) {
                            Button("キャンセル") {
                                cancelEditing()
                            }
                            .font(Typography.labelMedium.font)
                            .foregroundColor(SemanticColor.secondaryAction.color)
                            
                            Button("保存") {
                                saveChanges()
                            }
                            .font(Typography.labelMedium.font)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, Spacing.md.value)
                            .padding(.vertical, Spacing.sm.value)
                            .background(SemanticColor.primaryAction.color)
                            .cornerRadius(CornerRadius.small)
                        }
                    }
                }
                
                // Workout details section
                if let details = task.targetDetails {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: Spacing.sm.value) {
                        Label("詳細", systemImage: "info.circle")
                            .font(Typography.labelMedium.font)
                            .foregroundColor(SemanticColor.secondaryText.color)
                        
                        switch task.workoutType {
                        case .cycling:
                            CyclingDetailsEditView(details: details, isEditing: isEditing)
                        case .strength:
                            StrengthDetailsEditView(details: details, isEditing: isEditing)
                        case .flexibility, .pilates, .yoga:
                            FlexibilityDetailsEditView(details: details, isEditing: isEditing)
                        }
                    }
                }
                
                // Action buttons (when not editing)
                if !isEditing {
                    Divider()
                    
                    HStack(spacing: Spacing.md.value) {
                        Button(action: {
                            startEditing()
                        }) {
                            Label("編集", systemImage: "pencil")
                                .font(Typography.labelMedium.font)
                                .foregroundColor(SemanticColor.primaryAction.color)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.duplicateTask(task)
                        }) {
                            Label("複製", systemImage: "doc.on.doc")
                                .font(Typography.labelMedium.font)
                                .foregroundColor(SemanticColor.secondaryAction.color)
                        }
                        
                        Button(action: {
                            viewModel.showMoveTaskSheet(task)
                        }) {
                            Label("移動", systemImage: "arrow.right")
                                .font(Typography.labelMedium.font)
                                .foregroundColor(SemanticColor.secondaryAction.color)
                        }
                    }
                }
            }
        }
        .scaleEffect(isEditing ? 1.02 : 1.0)
        .animation(animationValue, value: isEditing)
        .onAppear {
            isEditing = viewModel.isTaskEditing(task)
            if isEditing {
                setupEditing()
            }
        }
        .onChange(of: viewModel.isTaskEditing(task)) { _, newValue in
            if newValue && !isEditing {
                startEditing()
            } else if !newValue && isEditing {
                cancelEditing()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func startEditing() {
        setupEditing()
        withAnimation(animationValue) {
            isEditing = true
        }
        
        // Delay focus to ensure TextField is rendered
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isTextFieldFocused = true
        }
        
        HapticManager.shared.trigger(.selection)
    }
    
    private func setupEditing() {
        editingTitle = task.title
        editingDescription = task.taskDescription ?? ""
    }
    
    private func saveChanges() {
        guard !editingTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            HapticManager.shared.trigger(.notification(.error))
            return
        }
        
        task.title = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        task.taskDescription = editingDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty 
            ? nil 
            : editingDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        
        withAnimation(animationValue) {
            isEditing = false
        }
        isTextFieldFocused = false
        
        viewModel.finishEditingTask(task)
    }
    
    private func cancelEditing() {
        withAnimation(animationValue) {
            isEditing = false
        }
        isTextFieldFocused = false
        
        // Reset to original values
        editingTitle = task.title
        editingDescription = task.taskDescription ?? ""
        
        viewModel.finishEditingTask(task)
        HapticManager.shared.trigger(.impact(.light))
    }
}

// MARK: - Detail Edit Views

struct CyclingDetailsEditView: View {
    let details: TargetDetails
    let isEditing: Bool
    
    var body: some View {
        HStack(spacing: Spacing.md.value) {
            if let duration = details.duration {
                DetailEditItem(
                    icon: "clock.fill",
                    label: "時間",
                    value: "\(duration)分",
                    isEditing: isEditing
                )
            }
            
            if let intensity = details.intensity {
                DetailEditItem(
                    icon: "bolt.fill",
                    label: "強度",
                    value: intensity.displayName,
                    isEditing: isEditing
                )
            }
            
            if let power = details.targetPower {
                DetailEditItem(
                    icon: "speedometer",
                    label: "パワー",
                    value: "\(power)W",
                    isEditing: isEditing
                )
            }
        }
    }
}

struct StrengthDetailsEditView: View {
    let details: TargetDetails
    let isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.value) {
            if let exercises = details.exercises, !exercises.isEmpty {
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor(SemanticColor.secondaryText.color)
                    Text(exercises.joined(separator: ", "))
                        .font(Typography.captionMedium.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                }
            }
            
            HStack(spacing: Spacing.md.value) {
                if let sets = details.targetSets {
                    DetailEditItem(
                        icon: "repeat",
                        label: "セット",
                        value: "\(sets)",
                        isEditing: isEditing
                    )
                }
                
                if let reps = details.targetReps {
                    DetailEditItem(
                        icon: "number",
                        label: "レップ",
                        value: "\(reps)",
                        isEditing: isEditing
                    )
                }
            }
        }
    }
}

struct FlexibilityDetailsEditView: View {
    let details: TargetDetails
    let isEditing: Bool
    
    var body: some View {
        HStack(spacing: Spacing.md.value) {
            if let duration = details.targetDuration {
                DetailEditItem(
                    icon: "clock.fill",
                    label: "時間",
                    value: "\(duration)分",
                    isEditing: isEditing
                )
            }
            
            if let forwardBend = details.targetForwardBend {
                DetailEditItem(
                    icon: "arrow.down",
                    label: "前屈",
                    value: "\(forwardBend)cm",
                    isEditing: isEditing
                )
            }
            
            if let splitAngle = details.targetSplitAngle {
                DetailEditItem(
                    icon: "angle",
                    label: "開脚",
                    value: "\(splitAngle)°",
                    isEditing: isEditing
                )
            }
        }
    }
}

struct DetailEditItem: View {
    let icon: String
    let label: String
    let value: String
    let isEditing: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(SemanticColor.secondaryText.color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(SemanticColor.secondaryText.color)
                Text(value)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(SemanticColor.primaryText.color)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(SemanticColor.surfaceBackground.color)
        .cornerRadius(CornerRadius.small)
        .scaleEffect(isEditing ? 0.95 : 1.0)
        .opacity(isEditing ? 0.7 : 1.0)
        .animation(.spring(response: 0.3), value: isEditing)
    }
}


// MARK: - Preview

#Preview("EditableTaskCard") {
    ScrollView {
        VStack(spacing: Spacing.md.value) {
            // Sample cycling task
            EditableTaskCard(
                task: DailyTask(
                    dayOfWeek: 1,
                    workoutType: .cycling,
                    title: "サイクリング",
                    isFlexible: false
                ),
                viewModel: WeeklyScheduleViewModel(modelContext: {
                    do {
                        return ModelContext(try ModelContainer(for: WeeklyTemplate.self))
                    } catch {
                        fatalError("Preview failed")
                    }
                }())
            )
        }
        .padding()
    }
    .background(SemanticColor.primaryBackground.color)
}