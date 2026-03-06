import SwiftUI

struct CommentaryPanel: View {
    let entries: [GameViewModel.CommentaryEntry]
    let isNarrating: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    if isNarrating {
                        WaveformView()
                    } else {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Text("COMMENTARY")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                if isNarrating {
                    HStack(spacing: 4) {
                        PulsingDot(color: .neonRed, size: 4)
                        Text("LIVE")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(.neonRed)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .overlay(Rectangle().fill(Color.cardBorder).frame(height: 1), alignment: .top)

            // Feed
            ScrollView {
                LazyVStack(spacing: 6) {
                    ForEach(entries) { entry in
                        CommentaryRow(entry: entry)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .background(Color.appBackground)
    }
}

// MARK: - Commentary Row

struct CommentaryRow: View {
    let entry: GameViewModel.CommentaryEntry

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Type badge
            Text(entry.type.emoji)
                .font(.system(size: 12))
                .frame(width: 20)

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.text)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineSpacing(1.5)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(entry.timeString)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.25))
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(eventColor(for: entry.type).opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(eventColor(for: entry.type).opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func eventColor(for type: GameEventType) -> Color {
        switch type {
        case .buy:      return .neonCyan
        case .trade:    return .neonViolet
        case .rent:     return .neonAmber
        case .bankrupt: return .neonRed
        case .jail:     return .neonAmber
        case .card:     return .neonPink
        case .tax:      return .neonRed
        case .build:    return .neonGreen
        default:        return .white
        }
    }
}

// MARK: - Extension for GameEventType emoji

extension GameEventType {
    var emoji: String {
        switch self {
        case .roll:     return "🎲"
        case .buy:      return "🏠"
        case .trade:    return "🤝"
        case .rent:     return "💰"
        case .bankrupt: return "💀"
        case .jail:     return "🔒"
        case .card:     return "🃏"
        case .tax:      return "🏛"
        case .build:    return "🏗"
        case .mortgage: return "📋"
        }
    }
}

// MARK: - Waveform View (Narrator Active)

struct WaveformView: View {
    @State private var heights: [CGFloat] = [4, 8, 12, 6, 10, 14, 8, 5, 11, 7]

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(heights.enumerated()), id: \.0) { idx, h in
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color.neonViolet)
                    .frame(width: 2, height: h)
                    .animation(
                        .easeInOut(duration: Double.random(in: 0.3...0.8))
                            .repeatForever(autoreverses: true)
                            .delay(Double(idx) * 0.05),
                        value: h
                    )
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                for i in heights.indices {
                    heights[i] = CGFloat.random(in: 3...16)
                }
            }
        }
    }
}
