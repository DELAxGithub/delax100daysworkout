import SwiftUI
import OSLog

// MARK: - Unified Workout Type Picker

struct UnifiedWorkoutTypePicker: View {
    @Binding var selectedType: WorkoutType
    let onSelectionChanged: ((WorkoutType) -> Void)?
    
    @State private var isExpanded = false
    
    init(
        selectedType: Binding<WorkoutType>,
        onSelectionChanged: ((WorkoutType) -> Void)? = nil
    ) {
        self._selectedType = selectedType
        self.onSelectionChanged = onSelectionChanged
    }
    
    var body: some View {
        BaseCard(
            style: OutlinedCardStyle(),
            onTap: {
                HapticManager.shared.trigger(.impact(.light))
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }
        ) {
            VStack(spacing: 0) {
                // Selected Type Display
                HStack(spacing: Spacing.md.value) {
                    Image(systemName: selectedType.iconName)
                        .font(.title2)
                        .foregroundColor(selectedType.iconColor)
                        .frame(width: 32, height: 32)
                    
                    VStack(alignment: .leading, spacing: Spacing.xs.value) {
                        Text("種目")
                            .font(Typography.captionMedium.font)
                            .foregroundColor(SemanticColor.secondaryText.color)
                        
                        Text(selectedType.rawValue)
                            .font(Typography.headlineMedium.font)
                            .foregroundColor(SemanticColor.primaryText.color)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(SemanticColor.secondaryText.color)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(Spacing.md.value)
                .frame(minHeight: 60)
                
                // Expanded Options
                if isExpanded {
                    Divider()
                        .padding(.horizontal, Spacing.md.value)
                    
                    VStack(spacing: 0) {
                        ForEach(WorkoutType.allCases, id: \.self) { type in
                            WorkoutTypeOption(
                                type: type,
                                isSelected: type == selectedType,
                                onTap: {
                                    selectType(type)
                                }
                            )
                        }
                    }
                    .padding(.vertical, Spacing.sm.value)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("種目選択")
        .accessibilityValue(selectedType.rawValue)
        .accessibilityHint("タップして種目を選択してください")
        .accessibilityAddTraits(.isButton)
    }
    
    private func selectType(_ type: WorkoutType) {
        HapticManager.shared.trigger(.selection)
        
        selectedType = type
        onSelectionChanged?(type)
        
        withAnimation(.easeInOut(duration: 0.2)) {
            isExpanded = false
        }
    }
}

// MARK: - Workout Type Option

private struct WorkoutTypeOption: View {
    let type: WorkoutType
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.md.value) {
                Image(systemName: type.iconName)
                    .font(.title3)
                    .foregroundColor(type.iconColor)
                    .frame(width: 28, height: 28)
                
                Text(type.rawValue)
                    .font(Typography.bodyLarge.font)
                    .foregroundColor(SemanticColor.primaryText.color)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(SemanticColor.primaryAction.color)
                }
            }
            .padding(.horizontal, Spacing.md.value)
            .padding(.vertical, Spacing.sm.value)
            .frame(minHeight: 44) // Apple HIG minimum touch target
            .background(
                isSelected ? 
                SemanticColor.primaryAction.color.opacity(0.1) : 
                Color.clear
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(type.rawValue)
        .accessibilityHint(isSelected ? "現在選択中の種目です" : "タップして選択")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

// MARK: - Preview

#Preview("UnifiedWorkoutTypePicker") {
    VStack(spacing: Spacing.lg.value) {
        UnifiedWorkoutTypePicker(
            selectedType: .constant(.cycling),
            onSelectionChanged: { type in
                Logger.debug.debug("Selected: \(type.rawValue)")
            }
        )
        
        UnifiedWorkoutTypePicker(
            selectedType: .constant(.flexibility),
            onSelectionChanged: { type in
                Logger.debug.debug("Selected: \(type.rawValue)")
            }
        )
        
        Spacer()
    }
    .padding()
    .background(SemanticColor.primaryBackground.color)
}