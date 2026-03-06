import SwiftUI

// MARK: - Colors

extension Color {
    // Background palette
    static let appBackground = Color(hex: "#080B14")
    static let cardBackground = Color(hex: "#0D1117")
    static let cardBorder = Color.white.opacity(0.08)
    static let surfaceHover = Color.white.opacity(0.04)

    // AI Player brand colors
    static let aiClaude    = Color(hex: "#7C3AED")
    static let aiGPT4      = Color(hex: "#10B981")
    static let aiGemini    = Color(hex: "#06B6D4")
    static let aiDeepSeek  = Color(hex: "#F59E0B")
    static let aiLLaMA     = Color(hex: "#EF4444")
    static let aiMistral   = Color(hex: "#EC4899")

    // Semantic colors
    static let neonViolet  = Color(hex: "#7C3AED")
    static let neonCyan    = Color(hex: "#06B6D4")
    static let neonGreen   = Color(hex: "#10B981")
    static let neonAmber   = Color(hex: "#F59E0B")
    static let neonRed     = Color(hex: "#EF4444")
    static let neonPink    = Color(hex: "#EC4899")

    // Board group colors
    static let boardBrown     = Color(hex: "#8B4513")
    static let boardLightBlue = Color(hex: "#87CEEB")
    static let boardPink      = Color(hex: "#FF69B4")
    static let boardOrange    = Color(hex: "#FFA500")
    static let boardRed       = Color(hex: "#FF0000")
    static let boardYellow    = Color(hex: "#FFD700")
    static let boardGreen     = Color(hex: "#228B22")
    static let boardDarkBlue  = Color(hex: "#00008B")

    // Utility initializer from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - ShapeStyle Extensions (enables dot-syntax in .foregroundStyle())

extension ShapeStyle where Self == Color {
    static var appBackground: Color { .init(hex: "#080B14") }
    static var cardBackground: Color { .init(hex: "#0D1117") }
    static var aiClaude: Color    { .init(hex: "#7C3AED") }
    static var aiGPT4: Color      { .init(hex: "#10B981") }
    static var aiGemini: Color    { .init(hex: "#06B6D4") }
    static var aiDeepSeek: Color  { .init(hex: "#F59E0B") }
    static var aiLLaMA: Color     { .init(hex: "#EF4444") }
    static var aiMistral: Color   { .init(hex: "#EC4899") }
    static var neonViolet: Color  { .init(hex: "#7C3AED") }
    static var neonCyan: Color    { .init(hex: "#06B6D4") }
    static var neonGreen: Color   { .init(hex: "#10B981") }
    static var neonAmber: Color   { .init(hex: "#F59E0B") }
    static var neonRed: Color     { .init(hex: "#EF4444") }
    static var neonPink: Color    { .init(hex: "#EC4899") }
}

// MARK: - AI Player Color Map

func aiPlayerColor(for playerID: String) -> Color {
    switch playerID.lowercased() {
    case "claude":   return .aiClaude
    case "gpt4":     return .aiGPT4
    case "gemini":   return .aiGemini
    case "deepseek": return .aiDeepSeek
    case "llama":    return .aiLLaMA
    case "mistral":  return .aiMistral
    default:         return .neonViolet
    }
}

// MARK: - Board Color Group Map

func boardGroupColor(for group: String) -> Color {
    switch group.lowercased() {
    case "brown":     return .boardBrown
    case "lightblue": return .boardLightBlue
    case "pink":      return .boardPink
    case "orange":    return .boardOrange
    case "red":       return .boardRed
    case "yellow":    return .boardYellow
    case "green":     return .boardGreen
    case "darkblue":  return .boardDarkBlue
    default:          return .gray
    }
}

// MARK: - Typography

enum AppFont {
    static func mono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("JetBrains Mono", size: size).weight(weight)
    }
    static func ui(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Inter", size: size).weight(weight)
    }
    // Fallback to system fonts if custom fonts not available
    static func monoFallback(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

// MARK: - Spacing & Sizing

enum Spacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

enum Radius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 10
    static let lg: CGFloat = 14
    static let xl: CGFloat = 20
}

// MARK: - Gradient Helpers

extension LinearGradient {
    static let violetToCyan = LinearGradient(
        colors: [.aiClaude, .aiGemini],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
