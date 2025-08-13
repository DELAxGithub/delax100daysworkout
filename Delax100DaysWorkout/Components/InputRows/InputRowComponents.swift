import SwiftUI

// MARK: - Numeric Input Row

struct NumericInputRow: View {
    let label: String
    @Binding var value: Int
    let unit: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(Typography.bodyLarge.font)
                .foregroundColor(SemanticColor.primaryText.color)
            
            Spacer()
            
            HStack(spacing: Spacing.xs.value) {
                TextField(placeholder, value: $value, format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(PlainTextFieldStyle())
                .font(Typography.bodyMedium.font)
                .padding(.horizontal, Spacing.sm.value)
                .padding(.vertical, Spacing.xs.value)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(SemanticColor.surfaceBackground.color)
                        .stroke(
                            SemanticColor.primaryBorder.color,
                            lineWidth: 1
                        )
                )
                .frame(width: 80)
                
                Text(unit)
                    .font(Typography.bodyMedium.font)
                    .foregroundColor(SemanticColor.secondaryText.color)
            }
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value) \(unit)")
        .accessibilityHint("数値を入力してください")
    }
}

// MARK: - Decimal Input Row

struct DecimalInputRow: View {
    let label: String
    @Binding var value: Double
    let unit: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(Typography.bodyLarge.font)
                .foregroundColor(SemanticColor.primaryText.color)
            
            Spacer()
            
            HStack(spacing: Spacing.xs.value) {
                TextField(placeholder, value: $value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .textFieldStyle(PlainTextFieldStyle())
                .font(Typography.bodyMedium.font)
                .padding(.horizontal, Spacing.sm.value)
                .padding(.vertical, Spacing.xs.value)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(SemanticColor.surfaceBackground.color)
                        .stroke(
                            SemanticColor.primaryBorder.color,
                            lineWidth: 1
                        )
                )
                .frame(width: 80)
                
                Text(unit)
                    .font(Typography.bodyMedium.font)
                    .foregroundColor(SemanticColor.secondaryText.color)
            }
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value, specifier: "%.1f") \(unit)")
        .accessibilityHint("数値を入力してください")
    }
}

// MARK: - Text Input Row

struct TextInputRow: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs.value) {
            Text(label)
                .font(Typography.bodyLarge.font)
                .foregroundColor(SemanticColor.primaryText.color)
            
            TextField(placeholder, text: $text)
            .textFieldStyle(PlainTextFieldStyle())
            .font(Typography.bodyMedium.font)
            .padding(.horizontal, Spacing.sm.value)
            .padding(.vertical, Spacing.xs.value)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(SemanticColor.surfaceBackground.color)
                    .stroke(
                        SemanticColor.primaryBorder.color,
                        lineWidth: 1
                    )
            )
            .frame(minHeight: 44)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue(text.isEmpty ? "未入力" : text)
    }
}

// MARK: - Slider Input Row

struct SliderInputRow: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs.value) {
            HStack {
                Text(label)
                    .font(Typography.bodyMedium.font)
                    .foregroundColor(SemanticColor.primaryText.color)
                
                Spacer()
                
                Text("\(value, specifier: "%.1f")")
                    .font(Typography.bodyMedium.font)
                    .foregroundColor(SemanticColor.secondaryText.color)
                    .padding(.horizontal, Spacing.sm.value)
                    .padding(.vertical, Spacing.xs.value)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(SemanticColor.surfaceBackground.color)
                    )
            }
            
            Slider(value: $value, in: range, step: step) { editing in
                if !editing {
                    HapticManager.shared.trigger(.selection)
                }
            }
            .tint(SemanticColor.primaryAction.color)
            .frame(minHeight: 44)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
        .accessibilityValue("\(value, specifier: "%.1f")")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(range.upperBound, value + step)
            case .decrement:
                value = max(range.lowerBound, value - step)
            @unknown default:
                break
            }
            HapticManager.shared.trigger(.selection)
        }
    }
}

// MARK: - Preview

#Preview("Input Row Components") {
    ScrollView {
        VStack(spacing: Spacing.lg.value) {
            BaseCard {
                VStack(spacing: Spacing.md.value) {
                    NumericInputRow(
                        label: "時間",
                        value: .constant(60),
                        unit: "分",
                        placeholder: "60"
                    )
                    
                    Divider()
                    
                    DecimalInputRow(
                        label: "目標前屈",
                        value: .constant(5.5),
                        unit: "cm",
                        placeholder: "0.0"
                    )
                    
                    Divider()
                    
                    TextInputRow(
                        label: "エクササイズタイプ",
                        text: .constant("Mat Pilates"),
                        placeholder: "例: Mat Pilates"
                    )
                    
                    Divider()
                    
                    SliderInputRow(
                        label: "コア強化",
                        value: .constant(7.5),
                        range: 0...10,
                        step: 0.5
                    )
                }
                .padding(Spacing.md.value)
            }
        }
        .padding()
    }
    .background(SemanticColor.primaryBackground.color)
}