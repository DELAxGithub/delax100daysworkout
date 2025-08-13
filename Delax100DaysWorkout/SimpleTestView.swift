import SwiftUI

struct SimpleTestView: View {
    var body: some View {
        VStack {
            Text("Hello Design System!")
                .font(Typography.headlineLarge.font)
                .foregroundColor(SemanticColor.primaryText.color)
                .padding(Spacing.md.value)
            
            BaseCard {
                Text("Simple Card Test")
                    .font(Typography.bodyMedium.font)
                    .foregroundColor(SemanticColor.secondaryText.color)
            }
            .padding(Spacing.lg.value)
        }
        .background(SemanticColor.primaryBackground.color)
    }
}

#Preview {
    SimpleTestView()
}