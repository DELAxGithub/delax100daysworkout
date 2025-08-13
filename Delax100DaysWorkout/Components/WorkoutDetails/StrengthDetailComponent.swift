import SwiftUI

// MARK: - Strength Detail Component

struct StrengthDetailComponent: View {
    @Binding var exercises: [String]
    @Binding var targetSets: Int
    @Binding var targetReps: Int
    
    var body: some View {
        BaseCard(style: OutlinedCardStyle()) {
            VStack(spacing: Spacing.md.value) {
                // Header
                HStack {
                    Image(systemName: WorkoutType.strength.iconName)
                        .font(.title2)
                        .foregroundColor(WorkoutType.strength.iconColor)
                    
                    Text("筋トレ詳細")
                        .font(Typography.headlineMedium.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                    
                    Spacer()
                }
                .padding(.bottom, Spacing.sm.value)
                
                // Exercises Section
                VStack(alignment: .leading, spacing: Spacing.sm.value) {
                    Text("エクササイズ")
                        .font(Typography.bodyLarge.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                    
                    ForEach(exercises.indices, id: \.self) { index in
                        ExerciseInputRow(
                            index: index + 1,
                            text: $exercises[index],
                            onDelete: exercises.count > 1 ? {
                                deleteExercise(at: index)
                            } : nil
                        )
                    }
                    
                    AddExerciseButton {
                        addExercise()
                    }
                }
                
                Divider()
                
                // Target Sets
                NumericInputRow(
                    label: "目標セット",
                    value: $targetSets,
                    unit: "セット",
                    placeholder: "3"
                )
                
                Divider()
                
                // Target Reps
                NumericInputRow(
                    label: "目標レップ",
                    value: $targetReps,
                    unit: "回",
                    placeholder: "10"
                )
            }
            .padding(Spacing.md.value)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("筋トレ詳細設定")
    }
    
    private func addExercise() {
        HapticManager.shared.trigger(.impact(.light))
        exercises.append("")
    }
    
    private func deleteExercise(at index: Int) {
        HapticManager.shared.trigger(.impact(.medium))
        exercises.remove(at: index)
        if exercises.isEmpty {
            exercises.append("")
        }
    }
}

// MARK: - Exercise Input Row

private struct ExerciseInputRow: View {
    let index: Int
    @Binding var text: String
    let onDelete: (() -> Void)?
    @State private var isEditing = false
    
    var body: some View {
        HStack(spacing: Spacing.sm.value) {
            Text("\(index).")
                .font(Typography.bodyMedium.font)
                .foregroundColor(SemanticColor.secondaryText.color)
                .frame(width: 24, alignment: .leading)
            
            TextField("エクササイズ名", text: $text, onEditingChanged: { editing in
                isEditing = editing
            })
            .textFieldStyle(PlainTextFieldStyle())
            .font(Typography.bodyMedium.font)
            .padding(.horizontal, Spacing.sm.value)
            .padding(.vertical, Spacing.xs.value)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(SemanticColor.surfaceBackground.color)
                    .stroke(
                        isEditing ? SemanticColor.primaryAction.color : SemanticColor.primaryBorder.color,
                        lineWidth: isEditing ? 2 : 1
                    )
            )
            .frame(minHeight: 44)
            
            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(SemanticColor.destructiveAction.color)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("エクササイズ\(index)を削除")
                .accessibilityHint("タップしてこのエクササイズを削除します")
            }
        }
    }
}

// MARK: - Add Exercise Button

private struct AddExerciseButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm.value) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 18))
                    .foregroundColor(SemanticColor.primaryAction.color)
                
                Text("エクササイズを追加")
                    .font(Typography.bodyMedium.font)
                    .foregroundColor(SemanticColor.primaryAction.color)
            }
            .frame(minHeight: 44)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Spacing.sm.value)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(SemanticColor.primaryAction.color.opacity(0.1))
                    .stroke(SemanticColor.primaryAction.color, style: StrokeStyle(lineWidth: 1, dash: [4]))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("エクササイズを追加")
        .accessibilityHint("タップして新しいエクササイズを追加します")
    }
}

// MARK: - Preview

#Preview("StrengthDetailComponent") {
    VStack(spacing: Spacing.lg.value) {
        StrengthDetailComponent(
            exercises: .constant(["Push-up", "Squat", ""]),
            targetSets: .constant(3),
            targetReps: .constant(10)
        )
        
        Spacer()
    }
    .padding()
    .background(SemanticColor.primaryBackground.color)
}