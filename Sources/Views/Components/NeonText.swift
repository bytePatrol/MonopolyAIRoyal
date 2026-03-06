import SwiftUI

// MARK: - NeonText ViewModifier

struct NeonTextModifier: ViewModifier {
    var color: Color
    var glowRadius: CGFloat = 8

    func body(content: Content) -> some View {
        content
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.8), radius: glowRadius / 2)
            .shadow(color: color.opacity(0.4), radius: glowRadius)
    }
}

extension View {
    func neonText(color: Color, glowRadius: CGFloat = 8) -> some View {
        modifier(NeonTextModifier(color: color, glowRadius: glowRadius))
    }
}

// MARK: - GradientText

struct GradientText: View {
    let text: String
    var gradient: LinearGradient = .violetToCyan
    var font: Font = .headline

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(gradient)
    }
}
