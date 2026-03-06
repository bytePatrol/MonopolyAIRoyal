import SwiftUI

// MARK: - GlassCard ViewModifier

struct GlassCardModifier: ViewModifier {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = Radius.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.cardBorder, lineWidth: 1)
                    )
            )
    }
}

extension View {
    func glassCard(padding: CGFloat = 16, cornerRadius: CGFloat = Radius.lg) -> some View {
        modifier(GlassCardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}

// MARK: - Neon Glow Modifier

struct NeonGlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.5), radius: radius / 2)
            .shadow(color: color.opacity(0.3), radius: radius)
    }
}

extension View {
    func neonGlow(color: Color, radius: CGFloat = 20) -> some View {
        modifier(NeonGlowModifier(color: color, radius: radius))
    }
}

// MARK: - GlassCard View

struct GlassCard<Content: View>: View {
    var padding: CGFloat = 16
    var cornerRadius: CGFloat = Radius.lg
    var borderColor: Color = Color.cardBorder
    var backgroundColor: Color = Color.cardBackground
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
    }
}
