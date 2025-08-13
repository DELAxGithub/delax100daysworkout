import SwiftUI

// MARK: - Color Token Catalog

struct ColorTokenCatalog: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg.value) {
                ColorSection(title: "Text Colors", colors: [
                    ("Primary Text", SemanticColor.primaryText),
                    ("Secondary Text", SemanticColor.secondaryText),
                    ("Tertiary Text", SemanticColor.tertiaryText),
                    ("Link Text", SemanticColor.linkText)
                ])
                
                ColorSection(title: "Background Colors", colors: [
                    ("Primary Background", SemanticColor.primaryBackground),
                    ("Secondary Background", SemanticColor.secondaryBackground),
                    ("Card Background", SemanticColor.cardBackground),
                    ("Surface Background", SemanticColor.surfaceBackground)
                ])
                
                ColorSection(title: "Action Colors", colors: [
                    ("Primary Action", SemanticColor.primaryAction),
                    ("Secondary Action", SemanticColor.secondaryAction),
                    ("Success Action", SemanticColor.successAction),
                    ("Warning Action", SemanticColor.warningAction),
                    ("Error Action", SemanticColor.errorAction),
                    ("Destructive Action", SemanticColor.destructiveAction)
                ])
            }
            .padding()
        }
        .navigationTitle("Color Tokens")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ColorSection: View {
    let title: String
    let colors: [(String, SemanticColor)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.value) {
            Text(title)
                .font(Typography.headlineSmall.font)
                .foregroundColor(SemanticColor.primaryText)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.sm.value) {
                ForEach(colors, id: \.0) { name, color in
                    ColorSwatch(name: name, color: color)
                }
            }
        }
    }
}

struct ColorSwatch: View {
    let name: String
    let color: SemanticColor
    
    var body: some View {
        VStack(spacing: Spacing.xs.value) {
            Rectangle()
                .fill(color.color)
                .frame(height: 60)
                .cornerRadius(CornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.medium.radius)
                        .strokeBorder(SemanticColor.primaryBorder.color, lineWidth: 1)
                )
            
            Text(name)
                .font(Typography.captionMedium.font)
                .foregroundColor(SemanticColor.primaryText)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Typography Catalog

struct TypographyCatalog: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg.value) {
                TypographySection(title: "Display", fonts: [
                    ("Display Large", Typography.displayLarge),
                    ("Display Medium", Typography.displayMedium),
                    ("Display Small", Typography.displaySmall)
                ])
                
                TypographySection(title: "Headlines", fonts: [
                    ("Headline Large", Typography.headlineLarge),
                    ("Headline Medium", Typography.headlineMedium),
                    ("Headline Small", Typography.headlineSmall)
                ])
                
                TypographySection(title: "Body", fonts: [
                    ("Body Large", Typography.bodyLarge),
                    ("Body Medium", Typography.bodyMedium),
                    ("Body Small", Typography.bodySmall)
                ])
                
                TypographySection(title: "Labels & Captions", fonts: [
                    ("Label Large", Typography.labelLarge),
                    ("Label Medium", Typography.labelMedium),
                    ("Caption Medium", Typography.captionMedium),
                    ("Caption Small", Typography.captionSmall)
                ])
            }
            .padding()
        }
        .navigationTitle("Typography")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TypographySection: View {
    let title: String
    let fonts: [(String, Typography)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.value) {
            Text(title)
                .font(Typography.headlineSmall.font)
                .foregroundColor(SemanticColor.primaryText)
            
            VStack(alignment: .leading, spacing: Spacing.xs.value) {
                ForEach(fonts, id: \.0) { name, typography in
                    TypographySample(name: name, typography: typography)
                }
            }
        }
    }
}

struct TypographySample: View {
    let name: String
    let typography: Typography
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Sample Text")
                .font(typography.font)
                .foregroundColor(SemanticColor.primaryText)
            
            Text(name)
                .font(Typography.captionSmall.font)
                .foregroundColor(SemanticColor.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, Spacing.xs.value)
    }
}

// MARK: - Spacing Catalog

struct SpacingCatalog: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg.value) {
                SpacingSection(title: "Basic Spacing", spacings: [
                    ("XS (4pt)", Spacing.xs),
                    ("SM (8pt)", Spacing.sm),
                    ("MD (16pt)", Spacing.md),
                    ("LG (24pt)", Spacing.lg),
                    ("XL (32pt)", Spacing.xl),
                    ("XXL (48pt)", Spacing.xxl)
                ])
                
                SpacingSection(title: "Component Spacing", spacings: [
                    ("Card Padding (16pt)", Spacing.cardPadding),
                    ("Card Spacing (20pt)", Spacing.cardSpacing),
                    ("Section Spacing (32pt)", Spacing.sectionSpacing),
                    ("List Item Spacing (12pt)", Spacing.listItemSpacing),
                    ("Button Padding (12pt)", Spacing.buttonPadding)
                ])
            }
            .padding()
        }
        .navigationTitle("Spacing Tokens")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SpacingSection: View {
    let title: String
    let spacings: [(String, Spacing)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm.value) {
            Text(title)
                .font(Typography.headlineSmall.font)
                .foregroundColor(SemanticColor.primaryText)
            
            VStack(alignment: .leading, spacing: Spacing.sm.value) {
                ForEach(spacings, id: \.0) { name, spacing in
                    SpacingSample(name: name, spacing: spacing)
                }
            }
        }
    }
}

struct SpacingSample: View {
    let name: String
    let spacing: Spacing
    
    var body: some View {
        HStack {
            Rectangle()
                .fill(SemanticColor.primaryAction.color)
                .frame(width: spacing.value, height: 20)
            
            Text(name)
                .font(Typography.bodySmall.font)
                .foregroundColor(SemanticColor.primaryText)
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#Preview("Color Catalog") {
    NavigationStack {
        ColorTokenCatalog()
    }
}

#Preview("Typography Catalog") {
    NavigationStack {
        TypographyCatalog()
    }
}

#Preview("Spacing Catalog") {
    NavigationStack {
        SpacingCatalog()
    }
}