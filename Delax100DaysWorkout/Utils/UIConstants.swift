import SwiftUI

struct UIConstants {
    // Colors
    static let primaryColor = Color.blue
    static let secondaryColor = Color.gray
    static let successColor = Color.green
    static let errorColor = Color.red
    static let warningColor = Color.orange
    
    // Spacing
    static let smallSpacing: CGFloat = 8
    static let mediumSpacing: CGFloat = 16
    static let largeSpacing: CGFloat = 24
    
    // Corner Radius
    static let smallRadius: CGFloat = 8
    static let mediumRadius: CGFloat = 12
    static let largeRadius: CGFloat = 16
    
    // Font Sizes
    static let smallFont = Font.caption
    static let mediumFont = Font.body
    static let largeFont = Font.title2
}

// Consistent Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(UIConstants.primaryColor)
            .foregroundColor(.white)
            .cornerRadius(UIConstants.mediumRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.primary)
            .cornerRadius(UIConstants.mediumRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}