import SwiftUI

struct AIFighterCard: View {
    let player: AIPlayer
    let isSelected: Bool
    let action: () -> Void

    @State private var isFlipped = false
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                if !isFlipped {
                    cardFront
                } else {
                    cardBack
                }
            }
            .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        }
        .buttonStyle(.plain)
        .frame(height: 200)
        .overlay(
            RoundedRectangle(cornerRadius: Radius.lg)
                .stroke(
                    isSelected ? player.color : Color.cardBorder,
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .neonGlow(color: player.color, radius: isSelected ? 16 : 0)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3), value: isHovered)
        .animation(.spring(response: 0.3), value: isSelected)
        .onHover { hover in
            isHovered = hover
        }
        .contextMenu {
            Button("View Stats") { isFlipped.toggle() }
            Button(isSelected ? "Deselect" : "Select") { action() }
        }
        .onTapGesture(count: 2) { isFlipped.toggle() }
    }

    // MARK: - Card Front

    private var cardFront: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name)
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundStyle(player.color)
                    Text(player.personality.rawValue)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
                // ELO badge
                VStack(alignment: .trailing, spacing: 1) {
                    Text("ELO")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                    Text("\(Int(player.elo))")
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .foregroundStyle(player.color)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)

            // Recent form dots
            HStack(spacing: 4) {
                ForEach(Array(player.recentForm.enumerated()), id: \.0) { _, result in
                    Text(result == .win ? "W" : "L")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(result == .win ? Color.neonGreen : Color.neonRed)
                        .frame(width: 18, height: 18)
                        .background(
                            Circle()
                                .fill(result == .win ? Color.neonGreen.opacity(0.15) : Color.neonRed.opacity(0.15))
                        )
                }
                Spacer()
                Text("\(Int(player.winRate))% WR")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)

            Divider()
                .background(Color.white.opacity(0.06))
                .padding(.horizontal, 14)
                .padding(.top, 10)

            // Stat bars
            VStack(spacing: 6) {
                statBar(label: "AGGRESSION", value: player.aggression, color: .neonRed)
                statBar(label: "TRADING",    value: player.trading,    color: .neonAmber)
                statBar(label: "EFFICIENCY", value: player.efficiency, color: .neonGreen)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)

            Spacer()

            // Bottom
            HStack {
                Text("\(player.totalGames)G PLAYED")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
                Spacer()
                if isSelected {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("SELECTED")
                    }
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(player.color)
                } else {
                    Text("DOUBLE-TAP TO FLIP")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.2))
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(Color.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.lg)
                        .fill(player.color.opacity(isSelected ? 0.05 : 0))
                )
        )
    }

    // MARK: - Card Back

    private var cardBack: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("STRATEGY PROFILE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
                Text(player.name)
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(player.color)
            }

            Divider().background(Color.white.opacity(0.06))

            strategyText

            Spacer()

            // Quick stats
            HStack(spacing: 16) {
                quickStat(label: "RISK", value: player.risk)
                quickStat(label: "TRADE", value: player.trading)
                quickStat(label: "AGG", value: player.aggression)
            }

            Text("DOUBLE-TAP TO FLIP BACK")
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(.white.opacity(0.2))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: Radius.lg)
                .fill(Color.cardBackground)
        )
        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
    }

    private var strategyText: some View {
        Text(strategyDescription)
            .font(.system(size: 11, design: .default))
            .foregroundStyle(.white.opacity(0.65))
            .lineSpacing(3)
    }

    private var strategyDescription: String {
        switch player.personality {
        case .aggressive:   return "Buys aggressively, builds fast. High risk, high reward. Aims to monopolize early and crush opponents with premium rents."
        case .conservative: return "Patient cash accumulation. Avoids risky trades. Wins by outlasting opponents through careful resource management."
        case .mathematical: return "Runs 10K simulations per decision. Pure EV maximization. No emotion, just optimal play verified by probability theory."
        case .tradeShark:   return "Masters the negotiating table. Acquires properties specifically to trade them. Monopoly is just poker with deeds."
        case .chaoticEvil:  return "ABSOLUTE CHAOS. Buys randomly, trades irrationally, and somehow wins. The quantum superposition of strategies."
        case .balanced:     return "Equal focus on all metrics. Adapts strategy to game state. No extreme positions — resilient in all game phases."
        }
    }

    private func statBar(label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 2) {
            HStack {
                Text(label)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
                Spacer()
                Text("\(value)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 3)
                        .cornerRadius(2)
                    Rectangle()
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(value) / 100, height: 3)
                        .cornerRadius(2)
                        .shadow(color: color.opacity(0.5), radius: 3)
                }
            }
            .frame(height: 3)
        }
    }

    private func quickStat(label: String, value: Int) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 16, weight: .black, design: .monospaced))
                .foregroundStyle(player.color)
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.3))
        }
    }
}
