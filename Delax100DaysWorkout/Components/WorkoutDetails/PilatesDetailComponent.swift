import SwiftUI

// MARK: - Pilates Detail Component

struct PilatesDetailComponent: View {
    @Binding var duration: Int
    @Binding var exerciseType: String
    @Binding var repetitions: Int
    @Binding var holdTime: Int
    @Binding var difficulty: PilatesDifficulty
    @Binding var coreEngagement: Double
    @Binding var posturalAlignment: Double
    @Binding var breathControl: Double
    
    var body: some View {
        BaseCard(style: OutlinedCardStyle()) {
            VStack(spacing: Spacing.md.value) {
                // Header
                HStack {
                    Image(systemName: WorkoutType.pilates.iconName)
                        .font(.title2)
                        .foregroundColor(WorkoutType.pilates.iconColor)
                    
                    Text("ピラティス詳細")
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
                    placeholder: "45"
                )
                
                Divider()
                
                // Exercise Type Input
                TextInputRow(
                    label: "エクササイズタイプ",
                    text: $exerciseType,
                    placeholder: "例: Mat Pilates"
                )
                
                Divider()
                
                // Difficulty Picker
                DifficultyPickerRow(
                    label: "難易度",
                    selection: $difficulty
                )
                
                Divider()
                
                // Repetitions Input
                NumericInputRow(
                    label: "反復回数",
                    value: $repetitions,
                    unit: "回",
                    placeholder: "12"
                )
                
                Divider()
                
                // Hold Time Input
                NumericInputRow(
                    label: "ホールド時間",
                    value: $holdTime,
                    unit: "秒",
                    placeholder: "30"
                )
                
                // Assessment Section
                VStack(alignment: .leading, spacing: Spacing.sm.value) {
                    Text("評価指標")
                        .font(Typography.bodyLarge.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                        .padding(.top, Spacing.sm.value)
                    
                    SliderInputRow(
                        label: "コア強化",
                        value: $coreEngagement,
                        range: 0...10,
                        step: 0.5
                    )
                    
                    SliderInputRow(
                        label: "姿勢改善",
                        value: $posturalAlignment,
                        range: 0...10,
                        step: 0.5
                    )
                    
                    SliderInputRow(
                        label: "呼吸制御",
                        value: $breathControl,
                        range: 0...10,
                        step: 0.5
                    )
                }
            }
            .padding(Spacing.md.value)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("ピラティス詳細設定")
    }
}

// MARK: - Difficulty Picker Row

private struct DifficultyPickerRow: View {
    let label: String
    @Binding var selection: PilatesDifficulty
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
                    ForEach(PilatesDifficulty.allCases, id: \.self) { difficulty in
                        Button(action: {
                            HapticManager.shared.trigger(.selection)
                            selection = difficulty
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = false
                            }
                        }) {
                            HStack {
                                Text(difficulty.rawValue)
                                    .font(Typography.bodyMedium.font)
                                    .foregroundColor(SemanticColor.primaryText.color)
                                
                                Spacer()
                                
                                if difficulty == selection {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(SemanticColor.primaryAction.color)
                                }
                            }
                            .padding(.horizontal, Spacing.sm.value)
                            .frame(minHeight: 40)
                            .background(
                                difficulty == selection ?
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
        .accessibilityHint("タップして難易度を選択してください")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview("PilatesDetailComponent") {
    VStack(spacing: Spacing.lg.value) {
        PilatesDetailComponent(
            duration: .constant(45),
            exerciseType: .constant("Mat Pilates"),
            repetitions: .constant(12),
            holdTime: .constant(30),
            difficulty: .constant(.intermediate),
            coreEngagement: .constant(7.0),
            posturalAlignment: .constant(6.5),
            breathControl: .constant(8.0)
        )
        
        Spacer()
    }
    .padding()
    .background(SemanticColor.primaryBackground.color)
}