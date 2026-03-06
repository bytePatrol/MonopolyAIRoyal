import SwiftUI

struct PlayerSidebarView: View {
    let state: GameState

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(state.players) { player in
                    PlayerStatusCard(
                        player: player,
                        state: state,
                        isActive: state.currentPlayer?.id == player.id
                    )
                }
            }
            .padding(12)
        }
        .background(Color.cardBackground)
    }
}

// MARK: - Player Status Card

struct PlayerStatusCard: View {
    let player: AIPlayer
    let state: GameState
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header row
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name)
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(player.isBankrupt ? .white.opacity(0.3) : player.color)
                        .lineLimit(1)
                    Text(player.personality.rawValue)
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                }
                Spacer()
                Text("$\(player.cash.formatted())")
                    .font(.system(size: 14, weight: .black, design: .monospaced))
                    .foregroundStyle(player.isBankrupt ? .white.opacity(0.2) : player.color)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)

            // Properties + Hotels
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Image(systemName: "house.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("\(player.propertyCount)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                }
                HStack(spacing: 4) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("\(player.hotelCount)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                if player.isInJail {
                    HStack(spacing: 3) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 8))
                        Text("JAIL")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(.neonAmber)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)

            // Net worth bar
            VStack(spacing: 3) {
                HStack {
                    Text("NET WORTH")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                    Spacer()
                    Text("$\(state.calculateNetWorth(for: player.id).formatted())")
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 3)
                        Rectangle()
                            .fill(player.color)
                            .frame(
                                width: geo.size.width * min(Double(state.calculateNetWorth(for: player.id)) / 6000.0, 1.0),
                                height: 3
                            )
                            .shadow(color: player.color.opacity(0.6), radius: 3)
                        if player.isBankrupt {
                            Text("BANKRUPT")
                                .font(.system(size: 7, weight: .bold, design: .monospaced))
                                .foregroundStyle(.neonRed)
                        }
                    }
                }
                .frame(height: 3)
            }
            .padding(.horizontal, 12)
            .padding(.top, 4)

            // Status row
            HStack {
                if isActive {
                    ThinkingDots(color: player.color)
                    Text("THINKING...")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(player.color)
                } else if player.isBankrupt {
                    Text("💀 BANKRUPT")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.neonRed.opacity(0.7))
                } else {
                    Text("WAITING")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.25))
                }
                Spacer()

                // Property color chips
                propertyChips
            }
            .padding(.horizontal, 12)
            .padding(.top, 6)
            .padding(.bottom, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isActive ? Color.white.opacity(0.06) : Color.white.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isActive ? player.color.opacity(0.5) : Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .shadow(color: isActive ? player.color.opacity(0.2) : .clear, radius: 10)
        .overlay(
            // Left accent bar
            Rectangle()
                .fill(player.color)
                .frame(width: 3)
                .cornerRadius(2),
            alignment: .leading
        )
        .opacity(player.isBankrupt ? 0.5 : 1.0)
    }

    private var propertyChips: some View {
        HStack(spacing: 2) {
            ForEach(ColorGroup.allCases, id: \.self) { group in
                let hasInGroup = state.board.contains { space in
                    space.colorGroup == group && space.ownerID == player.id
                }
                let hasMonopoly = state.hasMonopoly(playerID: player.id, group: group)
                if hasInGroup {
                    Circle()
                        .fill(group.color)
                        .frame(width: hasMonopoly ? 8 : 6, height: hasMonopoly ? 8 : 6)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: hasMonopoly ? 1 : 0)
                        )
                }
            }
        }
    }
}
