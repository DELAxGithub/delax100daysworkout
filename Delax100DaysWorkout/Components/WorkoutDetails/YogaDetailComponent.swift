import SwiftUI

// MARK: - Yoga Detail Component

struct YogaDetailComponent: View {
    @Binding var duration: Int
    @Binding var yogaStyle: YogaStyle
    @Binding var poses: [String]
    @Binding var breathingTechnique: String
    @Binding var flexibility: Double
    @Binding var balance: Double
    @Binding var mindfulness: Double
    @Binding var meditation: Bool
    
    var body: some View {
        BaseCard(style: OutlinedCardStyle()) {
            VStack(spacing: Spacing.md.value) {
                // Header
                HStack {
                    Image(systemName: WorkoutType.yoga.iconName)
                        .font(.title2)
                        .foregroundColor(WorkoutType.yoga.iconColor)
                    
                    Text("ヨガ詳細")
                        .font(Typography.headlineMedium.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                    
                    Spacer()
                }
                .padding(.bottom, Spacing.sm.value)
                
                // Duration Input
                NumericInputRow(
                    label: "時間",
                    value: $duration,
                    unit: "分",
                    placeholder: "60"
                )
                
                Divider()
                
                // Yoga Style Picker
                YogaStylePickerRow(
                    label: "ヨガスタイル",
                    selection: $yogaStyle
                )
                
                Divider()
                
                // Breathing Technique Input
                TextInputRow(
                    label: "呼吸法",
                    text: $breathingTechnique,
                    placeholder: "例: Ujjayi呼吸"
                )
                
                Divider()
                
                // Poses Section
                VStack(alignment: .leading, spacing: Spacing.sm.value) {
                    Text("ポーズ")
                        .font(Typography.bodyLarge.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                    
                    ForEach(poses.indices, id: \.self) { index in
                        PoseInputRow(
                            index: index + 1,
                            text: $poses[index],
                            onDelete: poses.count > 1 ? {
                                deletePose(at: index)
                            } : nil
                        )
                    }
                    
                    AddPoseButton {
                        addPose()
                    }
                }
                
                Divider()
                
                // Meditation Toggle
                HStack {
                    Text("瞑想を含む")
                        .font(Typography.bodyLarge.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                    
                    Spacer()
                    
                    Toggle("", isOn: $meditation)
                        .toggleStyle(SwitchToggleStyle())
                        .accessibilityLabel("瞑想を含む")
                }
                .frame(minHeight: 44)
                
                // Assessment Section
                VStack(alignment: .leading, spacing: Spacing.sm.value) {
                    Text("評価指標")
                        .font(Typography.bodyLarge.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                        .padding(.top, Spacing.sm.value)
                    
                    SliderInputRow(
                        label: "柔軟性",
                        value: $flexibility,
                        range: 0...10,
                        step: 0.5
                    )
                    
                    SliderInputRow(
                        label: "バランス",
                        value: $balance,
                        range: 0...10,
                        step: 0.5
                    )
                    
                    SliderInputRow(
                        label: "マインドフルネス",
                        value: $mindfulness,
                        range: 0...10,
                        step: 0.5
                    )
                }
            }
            .padding(Spacing.md.value)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("ヨガ詳細設定")
    }
    
    private func addPose() {
        HapticManager.shared.trigger(.impact(.light))
        poses.append("")
    }
    
    private func deletePose(at index: Int) {
        HapticManager.shared.trigger(.impact(.medium))
        poses.remove(at: index)
        if poses.isEmpty {
            poses.append("")
        }
    }
}

// MARK: - Yoga Style Picker Row

private struct YogaStylePickerRow: View {
    let label: String
    @Binding var selection: YogaStyle
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                HapticManager.shared.trigger(.impact(.light))
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(label)
                        .font(Typography.bodyLarge.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                    
                    Spacer()
                    
                    Text(selection.rawValue)
                        .font(Typography.bodyMedium.font)
                        .foregroundColor(SemanticColor.secondaryText.color)
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(SemanticColor.secondaryText.color)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .frame(minHeight: 44)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(YogaStyle.allCases, id: \.self) { style in
                        Button(action: {
                            HapticManager.shared.trigger(.selection)
                            selection = style
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = false
                            }
                        }) {
                            HStack {
                                Text(style.rawValue)
                                    .font(Typography.bodyMedium.font)
                                    .foregroundColor(SemanticColor.primaryText.color)
                                
                                Spacer()
                                
                                if style == selection {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(SemanticColor.primaryAction.color)
                                }
                            }
                            .padding(.horizontal, Spacing.sm.value)
                            .frame(minHeight: 40)
                            .background(
                                style == selection ?
                                SemanticColor.primaryAction.color.opacity(0.1) :
                                Color.clear
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.top, Spacing.xs.value)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label): \(selection.rawValue)")
        .accessibilityHint("タップしてヨガスタイルを選択してください")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Pose Input Row

private struct PoseInputRow: View {
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
            
            TextField("ポーズ名", text: $text, onEditingChanged: { editing in
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
                .accessibilityLabel("ポーズ\(index)を削除")
                .accessibilityHint("タップしてこのポーズを削除します")
            }
        }
    }
}

// MARK: - Add Pose Button

private struct AddPoseButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.sm.value) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 18))
                    .foregroundColor(SemanticColor.primaryAction.color)
                
                Text("ポーズを追加")
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
        .accessibilityLabel("ポーズを追加")
        .accessibilityHint("タップして新しいポーズを追加します")
    }
}

// MARK: - Preview

#Preview("YogaDetailComponent") {
    VStack(spacing: Spacing.lg.value) {
        YogaDetailComponent(
            duration: .constant(60),
            yogaStyle: .constant(.hatha),
            poses: .constant(["Mountain Pose", "Downward Dog", ""]),
            breathingTechnique: .constant("Ujjayi呼吸"),
            flexibility: .constant(8.0),
            balance: .constant(7.0),
            mindfulness: .constant(8.5),
            meditation: .constant(true)
        )
        
        Spacer()
    }
    .padding()
    .background(SemanticColor.primaryBackground.color)
}