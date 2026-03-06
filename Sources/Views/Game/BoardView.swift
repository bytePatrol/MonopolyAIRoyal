import SwiftUI

struct BoardView: View {
    let state: GameState
    let spaceSize: CGFloat = 52
    let cornerSize: CGFloat = 64

    var body: some View {
        ZStack {
            // Board background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "#0A0F1E"))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )

            // Center panel
            centerPanel

            // Board spaces
            ForEach(state.board) { space in
                let pos = space.gridPosition()
                let isCorner = space.isCorner
                let size: CGFloat = isCorner ? cornerSize : spaceSize

                BoardSpaceView(
                    space: space,
                    state: state,
                    isCorner: isCorner
                )
                .frame(width: size, height: size)
                .position(
                    x: cornerSize / 2 + CGFloat(pos.col) * spaceSize + (pos.col > 0 ? cornerSize - spaceSize : 0),
                    y: cornerSize / 2 + CGFloat(pos.row) * spaceSize + (pos.row > 0 ? cornerSize - spaceSize : 0)
                )
            }

            // Player tokens
            ForEach(state.players.filter { !$0.isBankrupt }) { player in
                let pos = state.board[player.boardPosition].gridPosition()
                PlayerToken(player: player, isActive: state.currentPlayer?.id == player.id)
                    .position(
                        x: tokenX(col: pos.col, playerID: player.id),
                        y: tokenY(row: pos.row, playerID: player.id)
                    )
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: player.boardPosition)
            }
        }
        .frame(width: boardWidth, height: boardHeight)
    }

    // MARK: - Dimensions

    private var boardWidth: CGFloat  { cornerSize * 2 + spaceSize * 9 }
    private var boardHeight: CGFloat { boardWidth }

    // MARK: - Center Panel

    private var centerPanel: some View {
        VStack(spacing: 12) {
            // Dice display
            if let roll = state.lastDiceRoll {
                diceDisplay(roll: roll)
            }

            // Current event
            if let event = state.events.last {
                VStack(spacing: 4) {
                    Text("LATEST")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                    Text(event.description)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.03))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.06)))
            }

            // Turn counter
            Text("TURN \(state.turn)")
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundStyle(.aiClaude)
        }
        .frame(
            width: boardWidth - cornerSize * 2 - 16,
            height: boardHeight - cornerSize * 2 - 16
        )
    }

    private func diceDisplay(roll: DiceRoll) -> some View {
        HStack(spacing: 8) {
            DieView(value: roll.die1)
            Text("+")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.3))
            DieView(value: roll.die2)
            Text("=")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.3))
            Text("\(roll.total)")
                .font(.system(size: 24, weight: .black, design: .monospaced))
                .foregroundStyle(.neonCyan)
        }
    }

    // MARK: - Token Positioning

    private func tokenX(col: Int, playerID: String) -> CGFloat {
        let base = cornerSize / 2 + CGFloat(col) * spaceSize + (col > 0 ? cornerSize - spaceSize : 0)
        let offset = tokenOffset(playerID: playerID)
        return base + offset.x
    }

    private func tokenY(row: Int, playerID: String) -> CGFloat {
        let base = cornerSize / 2 + CGFloat(row) * spaceSize + (row > 0 ? cornerSize - spaceSize : 0)
        let offset = tokenOffset(playerID: playerID)
        return base + offset.y
    }

    private func tokenOffset(playerID: String) -> CGPoint {
        let offsets: [String: CGPoint] = [
            "claude":   CGPoint(x: -8,  y: -8),
            "gpt4":     CGPoint(x: 8,   y: -8),
            "gemini":   CGPoint(x: -8,  y: 8),
            "deepseek": CGPoint(x: 8,   y: 8),
            "llama":    CGPoint(x: 0,   y: -12),
            "mistral":  CGPoint(x: 0,   y: 12),
        ]
        return offsets[playerID] ?? .zero
    }
}

// MARK: - Board Space View

struct BoardSpaceView: View {
    let space: BoardSpace
    let state: GameState
    let isCorner: Bool

    @State private var showTooltip = false
    @State private var isHovered = false

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 3)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(borderColor, lineWidth: 1)
                )

            // Content
            if isCorner {
                cornerContent
            } else {
                spaceContent
            }

            // Owner dot
            if let ownerID = space.ownerID {
                ownerIndicator(playerID: ownerID)
            }
        }
        .onHover { hovered in
            isHovered = hovered
            if hovered { showTooltip = true }
        }
        .popover(isPresented: $showTooltip) {
            SpaceTooltipView(space: space, state: state)
        }
    }

    // MARK: - Backgrounds

    private var backgroundColor: Color {
        if let group = space.colorGroup {
            return group.color.opacity(0.12)
        }
        switch space.type {
        case .corner:   return Color.white.opacity(0.04)
        case .tax:      return Color.neonRed.opacity(0.08)
        case .railroad: return Color.white.opacity(0.06)
        case .utility:  return Color.neonAmber.opacity(0.08)
        case .card:     return Color.neonViolet.opacity(0.06)
        default:        return Color.white.opacity(0.02)
        }
    }

    private var borderColor: Color {
        if isHovered { return Color.white.opacity(0.3) }
        if let group = space.colorGroup { return group.color.opacity(0.3) }
        return Color.white.opacity(0.06)
    }

    // MARK: - Content Views

    private var cornerContent: some View {
        VStack(spacing: 1) {
            Text(cornerEmoji)
                .font(.system(size: 18))
            Text(space.name)
                .font(.system(size: 6, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
    }

    private var cornerEmoji: String {
        switch space.name {
        case "GO":          return "🚀"
        case "JAIL":        return "🔒"
        case "Free Parking": return "🅿️"
        case "GO TO JAIL":  return "👮"
        default:            return "⭐️"
        }
    }

    private var spaceContent: some View {
        VStack(spacing: 1) {
            // Color bar at top for properties
            if let group = space.colorGroup {
                Rectangle()
                    .fill(group.color)
                    .frame(height: 5)
                    .frame(maxWidth: .infinity)
                    .cornerRadius(1)
                    .shadow(color: group.color, radius: 2)
            }

            // House/hotel indicators
            if space.hasHotel {
                Image(systemName: "house.fill")
                    .font(.system(size: 7))
                    .foregroundStyle(.neonRed)
            } else if space.houses > 0 {
                HStack(spacing: 1) {
                    ForEach(0..<space.houses, id: \.self) { _ in
                        Rectangle()
                            .fill(.neonGreen)
                            .frame(width: 4, height: 4)
                    }
                }
            }

            // Name
            Text(shortName)
                .font(.system(size: 5.5, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 1)

            // Price
            if let price = space.price {
                Text("$\(price)")
                    .font(.system(size: 5.5, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(2)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var shortName: String {
        let name = space.name
        if name.count <= 8 { return name }
        // Shorten long names
        return name.components(separatedBy: " ")
            .prefix(2)
            .joined(separator: "\n")
    }

    private func ownerIndicator(playerID: String) -> some View {
        VStack {
            HStack {
                Circle()
                    .fill(aiPlayerColor(for: playerID))
                    .frame(width: 5, height: 5)
                    .neonGlow(color: aiPlayerColor(for: playerID), radius: 3)
                    .padding(2)
                Spacer()
            }
            Spacer()
        }
    }
}

// MARK: - Space Tooltip

struct SpaceTooltipView: View {
    let space: BoardSpace
    let state: GameState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(space.name.uppercased())
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundStyle(space.colorGroup?.color ?? .white)

            if let price = space.price {
                tooltipRow(label: "Price", value: "$\(price)")
            }
            if let ownerID = space.ownerID {
                tooltipRow(label: "Owner", value: ownerID.uppercased(), valueColor: aiPlayerColor(for: ownerID))
            }
            if let rent = space.baseRent, space.type == .property {
                tooltipRow(label: "Base Rent", value: "$\(rent)")
                if let h1 = space.rent1 { tooltipRow(label: "1 House",  value: "$\(h1)") }
                if let h2 = space.rent2 { tooltipRow(label: "2 Houses", value: "$\(h2)") }
                if let h3 = space.rent3 { tooltipRow(label: "3 Houses", value: "$\(h3)") }
                if let h4 = space.rent4 { tooltipRow(label: "4 Houses", value: "$\(h4)") }
                if let hr = space.hotelRent { tooltipRow(label: "Hotel",   value: "$\(hr)") }
            }
            if space.houses > 0 || space.hasHotel {
                Divider()
                tooltipRow(label: "Development",
                           value: space.hasHotel ? "🏨 Hotel" : "\(space.houses) 🏠")
            }
        }
        .padding(12)
        .background(Color.cardBackground)
        .cornerRadius(8)
    }

    private func tooltipRow(label: String, value: String, valueColor: Color = .white) -> some View {
        HStack(spacing: 8) {
            Text(label + ":")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
                .frame(width: 70, alignment: .leading)
            Text(value)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(valueColor.opacity(0.9))
        }
    }
}

// MARK: - Die View

struct DieView: View {
    let value: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.08))
                .frame(width: 32, height: 32)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )

            Text(diePip)
                .font(.system(size: 16))
        }
    }

    private var diePip: String {
        ["⚀","⚁","⚂","⚃","⚄","⚅"][min(max(value-1, 0), 5)]
    }
}

// MARK: - Player Token

struct PlayerToken: View {
    let player: AIPlayer
    let isActive: Bool

    @State private var pulse = false

    var body: some View {
        ZStack {
            if isActive {
                Circle()
                    .stroke(player.color, lineWidth: 2)
                    .frame(width: 22, height: 22)
                    .opacity(pulse ? 0 : 0.6)
                    .scaleEffect(pulse ? 1.8 : 1.0)
                    .animation(.easeOut(duration: 1.0).repeatForever(autoreverses: false), value: pulse)
            }

            Circle()
                .fill(player.color)
                .frame(width: 14, height: 14)
                .overlay(
                    Text(String(player.name.prefix(1)))
                        .font(.system(size: 7, weight: .black))
                        .foregroundStyle(.white)
                )
                .shadow(color: player.color.opacity(0.8), radius: isActive ? 6 : 2)
        }
        .onAppear { pulse = isActive }
        .onChange(of: isActive) { _, active in pulse = active }
    }
}
