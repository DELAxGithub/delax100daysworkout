import SwiftUI

// MARK: - Cycling Detail Component

struct CyclingDetailComponent: View {
    @Binding var duration: Int
    @Binding var intensity: CyclingIntensity
    @Binding var targetPower: Int
    
    var body: some View {
        BaseCard(style: OutlinedCardStyle()) {
            VStack(spacing: Spacing.md.value) {
                // Header
                HStack {
                    Image(systemName: WorkoutType.cycling.iconName)
                        .font(.title2)
                        .foregroundColor(WorkoutType.cycling.iconColor)
                    
                    Text("サイクリング詳細")
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
                
                // Intensity Picker
                IntensityPickerRow(
                    label: "強度",
                    selection: $intensity
                )
                
                Divider()
                
                // Target Power Input
                NumericInputRow(
                    label: "目標パワー",
                    value: $targetPower,
                    unit: "W",
                    placeholder: "200"
                )
            }
            .padding(Spacing.md.value)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("サイクリング詳細設定")
    }
}

// MARK: - Intensity Picker Row

private struct IntensityPickerRow: View {
    let label: String
    @Binding var selection: CyclingIntensity
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
                    
                    Text(selection.displayName)
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
                    ForEach(CyclingIntensity.allCases, id: \.self) { intensity in
                        Button(action: {
                            HapticManager.shared.trigger(.selection)
                            selection = intensity
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = false
                            }
                        }) {
                            HStack {
                                Text(intensity.displayName)
                                    .font(Typography.bodyMedium.font)
                                    .foregroundColor(SemanticColor.primaryText.color)
                                
                                Spacer()
                                
                                if intensity == selection {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(SemanticColor.primaryAction.color)
                                }
                            }
                            .padding(.horizontal, Spacing.sm.value)
                            .frame(minHeight: 40)
                            .background(
                                intensity == selection ?
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
        .accessibilityLabel("\(label): \(selection.displayName)")
        .accessibilityHint("タップして強度を選択してください")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Preview

#Preview("CyclingDetailComponent") {
    VStack(spacing: Spacing.lg.value) {
        CyclingDetailComponent(
            duration: .constant(60),
            intensity: .constant(.endurance),
            targetPower: .constant(200)
        )
        
        Spacer()
    }
    .padding()
    .background(SemanticColor.primaryBackground.color)
}