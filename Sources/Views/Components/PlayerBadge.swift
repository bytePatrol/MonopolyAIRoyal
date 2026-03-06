import SwiftUI

struct PlayerBadge: View {
    let name: String
    let color: Color
    var fontSize: CGFloat = 11

    var body: some View {
        Text(name.uppercased())
            .font(.system(size: fontSize, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                Capsule()
                    .fill(color.opacity(0.15))
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.4), lineWidth: 1)
                    )
            )
    }
}

struct PersonalityBadge: View {
    let personality: String
    var color: Color = .white

    var body: some View {
        Text(personality.uppercased())
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(color.opacity(0.5))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(color.opacity(0.05))
                    .overlay(
                        Capsule()
                            .stroke(color.opacity(0.15), lineWidth: 1)
                    )
            )
    }
}

struct StatusBadge: View {
    enum Status { case ready, thinking, waiting, bankrupt }
    let status: Status

    var label: String {
        switch status {
        case .ready:    return "READY"
        case .thinking: return "THINKING"
        case .waiting:  return "WAITING"
        case .bankrupt: return "BANKRUPT"
        }
    }

    var color: Color {
        switch status {
        case .ready:    return .neonGreen
        case .thinking: return .neonViolet
        case .waiting:  return .white.opacity(0.4)
        case .bankrupt: return .neonRed
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            if status == .thinking {
                ThinkingDots(color: color)
            } else {
                Circle()
                    .fill(color)
                    .frame(width: 5, height: 5)
            }
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(color)
        }
    }
}
