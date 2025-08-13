import SwiftUI

// MARK: - Flexibility Detail Component

struct FlexibilityDetailComponent: View {
    @Binding var targetDuration: Int
    @Binding var targetForwardBend: Double
    @Binding var targetSplitAngle: Double
    
    var body: some View {
        BaseCard(style: OutlinedCardStyle()) {
            VStack(spacing: Spacing.md.value) {
                // Header
                HStack {
                    Image(systemName: WorkoutType.flexibility.iconName)
                        .font(.title2)
                        .foregroundColor(WorkoutType.flexibility.iconColor)
                    
                    Text("柔軟性詳細")
                        .font(Typography.headlineMedium.font)
                        .foregroundColor(SemanticColor.primaryText.color)
                    
                    Spacer()
                }
                .padding(.bottom, Spacing.sm.value)
                
                // Duration Input
                NumericInputRow(
                    label: "時間",
                    value: $targetDuration,
                    unit: "分",
                    placeholder: "20"
                )
                
                Divider()
                
                // Forward Bend Input
                DecimalInputRow(
                    label: "目標前屈",
                    value: $targetForwardBend,
                    unit: "cm",
                    placeholder: "0.0"
                )
                
                Divider()
                
                // Split Angle Input
                DecimalInputRow(
                    label: "目標開脚",
                    value: $targetSplitAngle,
                    unit: "°",
                    placeholder: "120.0"
                )
            }
            .padding(Spacing.md.value)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("柔軟性詳細設定")
    }
}

// MARK: - Preview

#Preview("FlexibilityDetailComponent") {
    VStack(spacing: Spacing.lg.value) {
        FlexibilityDetailComponent(
            targetDuration: .constant(20),
            targetForwardBend: .constant(5.0),
            targetSplitAngle: .constant(120.0)
        )
        
        Spacer()
    }
    .padding()
    .background(SemanticColor.primaryBackground.color)
}