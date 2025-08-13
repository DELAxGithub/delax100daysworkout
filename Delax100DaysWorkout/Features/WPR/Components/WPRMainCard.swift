import SwiftUI

// MARK: - WPR Main Card Component (Extracted & Refactored)

struct WPRMainCard: View {
    let system: WPRTrackingSystem
    let onTargetSettingsTap: () -> Void
    @State private var animatedProgress: Double = 0
    @State private var animatedWPR: Double = 0
    
    private var progressRatio: Double {
        system.targetProgressRatio
    }
    
    private var currentWPR: Double {
        system.calculatedWPR
    }
    
    private var targetWPR: Double {
        system.targetWPR
    }
    
    private var daysRemaining: Int? {
        if let targetDate = system.targetDate {
            let calendar = Calendar.current
            let days = calendar.dateComponents([.day], from: Date(), to: targetDate).day
            return days ?? system.daysToTarget
        }
        return system.daysToTarget
    }
    
    var body: some View {
        BaseCard {
            VStack(spacing: Spacing.md.value) {
                WPRMainCardHeader(system: system, onTargetSettingsTap: onTargetSettingsTap)
                WPRMainCardMetrics(
                    currentWPR: animatedWPR,
                    targetWPR: targetWPR,
                    progressRatio: animatedProgress,
                    system: system
                )
                WPRMainCardStats(
                    daysRemaining: daysRemaining,
                    currentWPR: currentWPR,
                    system: system
                )
                WPRMainCardBottleneck(currentWPR: currentWPR, system: system)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = progressRatio
                animatedWPR = currentWPR
            }
        }
        .onChange(of: currentWPR) { _, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                animatedWPR = newValue
            }
        }
        .onChange(of: progressRatio) { _, newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Header Component

private struct WPRMainCardHeader: View {
    let system: WPRTrackingSystem
    let onTargetSettingsTap: () -> Void
    
    var body: some View {
        HStack {
            HStack(spacing: Spacing.sm.value) {
                Image(systemName: "target")
                    .font(Typography.headlineMedium.font)
                    .foregroundColor(SemanticColor.primaryAction)
                
                Text("WPR 4.5 達成への道のり")
                    .font(Typography.headlineMedium)
                    .foregroundColor(SemanticColor.primaryText)
            }
            
            Spacer()
        }
    }
}

// MARK: - Metrics Component

private struct WPRMainCardMetrics: View {
    let currentWPR: Double
    let targetWPR: Double
    let progressRatio: Double
    let system: WPRTrackingSystem
    
    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.lg.value) {
            WPRCurrentValue(currentWPR: currentWPR)
            Spacer()
            WPRProgressIndicator(progressRatio: progressRatio)
            Spacer()
            WPRTargetValue(targetWPR: targetWPR, system: system, onTargetSettingsTap: {})
        }
    }
}

// MARK: - Value Display Components

private struct WPRCurrentValue: View {
    let currentWPR: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs.value) {
            if currentWPR > 0 {
                Text(String(format: "%.1f", currentWPR))
                    .font(Typography.displayLarge)
                    .foregroundColor(SemanticColor.primaryAction)
                    .contentTransition(.numericText())
            } else {
                VStack(spacing: Spacing.xs.value) {
                    Text("--")
                        .font(Typography.displayLarge)
                        .foregroundColor(SemanticColor.secondaryText)
                    
                    Text("データを入力してください")
                        .font(Typography.captionSmall)
                        .foregroundColor(SemanticColor.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            
            Text("現在")
                .font(Typography.captionMedium)
                .foregroundColor(SemanticColor.secondaryText)
        }
    }
}

private struct WPRProgressIndicator: View {
    let progressRatio: Double
    
    var body: some View {
        VStack(spacing: Spacing.sm.value) {
            ProgressView(value: progressRatio)
                .progressViewStyle(LinearProgressViewStyle(
                    tint: progressColor
                ))
                .frame(width: 120, height: 12)
            
            Text("\(Int(progressRatio * 100))%")
                .font(Typography.displaySmall)
                .foregroundColor(SemanticColor.primaryText)
                .contentTransition(.numericText())
        }
    }
    
    private var progressColor: Color {
        switch progressRatio {
        case 0.8...: return SemanticColor.successAction.color
        case 0.6..<0.8: return SemanticColor.primaryAction.color
        case 0.4..<0.6: return SemanticColor.warningAction.color
        default: return SemanticColor.errorAction.color
        }
    }
}

private struct WPRTargetValue: View {
    let targetWPR: Double
    let system: WPRTrackingSystem
    let onTargetSettingsTap: () -> Void
    
    var body: some View {
        VStack(alignment: .trailing, spacing: Spacing.xs.value) {
            HStack(spacing: Spacing.xs.value) {
                Text(String(format: "%.1f", targetWPR))
                    .font(Typography.displayLarge)
                    .foregroundColor(SemanticColor.successAction)
                
                Button(action: onTargetSettingsTap) {
                    Image(systemName: "gear")
                        .font(Typography.labelSmall)
                        .foregroundColor(SemanticColor.primaryAction)
                        .padding(Spacing.xs)
                        .background(SemanticColor.secondaryBackground)
                        .cornerRadius(.small)
                }
            }
            
            Text(system.isCustomTargetSet ? "カスタム目標" : "デフォルト目標")
                .font(Typography.captionMedium)
                .foregroundColor(SemanticColor.secondaryText)
        }
    }
}

// MARK: - Stats Component

private struct WPRMainCardStats: View {
    let daysRemaining: Int?
    let currentWPR: Double
    let system: WPRTrackingSystem
    
    private var monthlyGain: Double {
        max(0.1, (system.targetWPR - currentWPR) / 3.0)
    }
    
    var body: some View {
        HStack(spacing: Spacing.lg.value) {
            WPRStatItem(
                icon: "calendar",
                value: daysText,
                label: "残り期間",
                color: SemanticColor.primaryAction
            )
            
            Spacer()
            
            WPRStatItem(
                icon: "chart.line.uptrend.xyaxis",
                value: currentWPR > 0 ? "月間 +\(String(format: "%.1f", monthlyGain))" : "予測計算中",
                label: "WPR向上",
                color: SemanticColor.successAction
            )
            
            Spacer()
        }
    }
    
    private var daysText: String {
        if currentWPR > 0 {
            if let days = daysRemaining, days > 0 {
                return "残り \(days)日"
            } else {
                return "目標達成済み"
            }
        } else {
            return "データ待ち"
        }
    }
}

private struct WPRStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: SemanticColor
    
    var body: some View {
        HStack(spacing: Spacing.sm.value) {
            Image(systemName: icon)
                .font(Typography.labelMedium)
                .foregroundColor(color)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(Typography.labelMedium)
                    .foregroundColor(SemanticColor.primaryText)
            }
        }
    }
}

// MARK: - Bottleneck Component

private struct WPRMainCardBottleneck: View {
    let currentWPR: Double
    let system: WPRTrackingSystem
    
    var body: some View {
        if currentWPR > 0 {
            HStack(spacing: Spacing.sm.value) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(Typography.labelMedium)
                    .foregroundColor(SemanticColor.warningAction)
                
                Text("ボトルネック: \(system.currentBottleneck.rawValue)")
                    .font(Typography.labelMedium)
                    .foregroundColor(SemanticColor.primaryText)
                
                Spacer()
            }
        } else {
            WPRSetupGuide()
        }
    }
}

private struct WPRSetupGuide: View {
    var body: some View {
        VStack(spacing: Spacing.sm.value) {
            HStack(spacing: Spacing.sm.value) {
                Image(systemName: "info.circle.fill")
                    .font(Typography.labelMedium)
                    .foregroundColor(SemanticColor.primaryAction)
                
                Text("FTPと体重を記録してWPR計算を開始")
                    .font(Typography.labelMedium)
                    .foregroundColor(SemanticColor.primaryText)
                
                Spacer()
            }
            
            HStack(spacing: Spacing.lg.value) {
                NavigationLink(destination: EmptyView()) {
                    Text("FTP記録")
                        .font(Typography.labelSmall)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(SemanticColor.primaryAction)
                        .cornerRadius(.medium)
                }
                
                NavigationLink(destination: EmptyView()) {
                    Text("体重記録")
                        .font(Typography.labelSmall)
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.sm)
                        .background(SemanticColor.successAction)
                        .cornerRadius(.medium)
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    WPRMainCard(
        system: WPRTrackingSystem.sampleData(),
        onTargetSettingsTap: {}
    )
    .padding()
}