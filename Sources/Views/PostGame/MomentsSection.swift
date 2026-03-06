import SwiftUI

struct MomentsSection: View {
    let moments: [GameMoment]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(title: "TOP MOMENTS", subtitle: "The plays that defined the game")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(moments) { moment in
                        MomentCard(moment: moment)
                    }
                }
            }
        }
    }

    private func sectionHeader(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 16, weight: .black, design: .monospaced))
                .foregroundStyle(.white.opacity(0.9))
            Text(subtitle.uppercased())
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.3))
        }
    }
}

// MARK: - Moment Card

struct MomentCard: View {
    let moment: GameMoment

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Turn badge
            HStack {
                Text("TURN \(moment.turn)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(4)
                Spacer()
                Text(moment.eventType.emoji)
                    .font(.system(size: 18))
            }

            // Board thumbnail (mini colored square)
            RoundedRectangle(cornerRadius: 8)
                .fill(eventTypeColor(moment.eventType).opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(eventTypeColor(moment.eventType).opacity(0.25), lineWidth: 1)
                )
                .overlay(
                    VStack(spacing: 4) {
                        Text(moment.eventType.emoji)
                            .font(.system(size: 32))
                        if let amount = moment.amount {
                            Text("$\(amount)")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundStyle(eventTypeColor(moment.eventType))
                        }
                    }
                )
                .frame(height: 100)

            // Title
            Text(moment.title.uppercased())
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundStyle(eventTypeColor(moment.eventType))

            // Description
            Text(moment.description)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.65))
                .lineSpacing(2)
                .lineLimit(3)
        }
        .padding(14)
        .frame(width: 200)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isHovered ? eventTypeColor(moment.eventType).opacity(0.4) : Color.cardBorder,
                    lineWidth: 1
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .onHover { isHovered = $0 }
    }

    private func eventTypeColor(_ type: GameEventType) -> Color {
        switch type {
        case .buy:      return .neonCyan
        case .trade:    return .neonViolet
        case .rent:     return .neonAmber
        case .bankrupt: return .neonRed
        case .mortgage: return .white.opacity(0.5)
        default:        return .neonGreen
        }
    }
}
