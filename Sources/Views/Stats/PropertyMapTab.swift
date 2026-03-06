import SwiftUI

struct PropertyMapTab: View {
    @Environment(StatsViewModel.self) private var vm

    private let mockState = GameState.mockState()

    var body: some View {
        HStack(spacing: 0) {
            // Mini board heatmap
            VStack(alignment: .leading, spacing: 12) {
                Text("PROPERTY OWNERSHIP MAP")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                miniBoard

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.cardBackground)
            .overlay(Rectangle().fill(Color.cardBorder).frame(width: 1), alignment: .trailing)

            // Right: Top properties + timeline
            ScrollView {
                VStack(spacing: 16) {
                    topPropertiesSection
                    acquisitionTimeline
                }
                .padding(16)
            }
            .frame(width: 280)
            .background(Color.appBackground)
        }
    }

    // MARK: - Mini Board

    private var miniBoard: some View {
        let spaceSize: CGFloat = 22
        let cornerSize: CGFloat = 28

        return ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "#0A0F1E"))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )

            ForEach(mockState.board) { space in
                let pos = space.gridPosition()
                let isCorner = space.isCorner
                let size: CGFloat = isCorner ? cornerSize : spaceSize

                miniSpaceView(space)
                    .frame(width: size, height: size)
                    .position(
                        x: cornerSize / 2 + CGFloat(pos.col) * spaceSize + (pos.col > 0 ? cornerSize - spaceSize : 0),
                        y: cornerSize / 2 + CGFloat(pos.row) * spaceSize + (pos.row > 0 ? cornerSize - spaceSize : 0)
                    )
            }
        }
        .frame(
            width: cornerSize * 2 + spaceSize * 9,
            height: cornerSize * 2 + spaceSize * 9
        )
        .padding(.horizontal, 20)
    }

    private func miniSpaceView(_ space: BoardSpace) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 2)
                .fill(miniSpaceColor(space))
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                )

            if let ownerID = space.ownerID {
                Circle()
                    .fill(aiPlayerColor(for: ownerID))
                    .frame(width: 5, height: 5)
                    .shadow(color: aiPlayerColor(for: ownerID), radius: 2)
            }
        }
    }

    private func miniSpaceColor(_ space: BoardSpace) -> Color {
        if space.ownerID != nil { return space.colorGroup?.color.opacity(0.4) ?? Color.white.opacity(0.15) }
        if let group = space.colorGroup { return group.color.opacity(0.08) }
        return Color.white.opacity(0.03)
    }

    // MARK: - Top Properties

    private var topPropertiesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("TOP 10 PROPERTIES")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))

            let topProps = mockState.board
                .filter { $0.type == .property && $0.price != nil }
                .sorted { ($0.hotelRent ?? 0) > ($1.hotelRent ?? 0) }
                .prefix(10)

            ForEach(Array(topProps.enumerated()), id: \.1.id) { idx, space in
                HStack {
                    Text("\(idx + 1)")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                        .frame(width: 14)

                    if let group = space.colorGroup {
                        Circle()
                            .fill(group.color)
                            .frame(width: 6, height: 6)
                    }

                    Text(space.name)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)

                    Spacer()

                    if let hotelRent = space.hotelRent {
                        Text("$\(hotelRent)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(.neonAmber)
                    }
                }
                .padding(.vertical, 3)
            }
        }
        .padding(12)
        .glassCard(padding: 0, cornerRadius: 8)
    }

    // MARK: - Acquisition Timeline

    private var acquisitionTimeline: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ACQUISITION TIMELINE")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))

            let events: [(Int, String, String, Color)] = [
                (8, "CLAUDE", "Mediterranean Ave", .aiClaude),
                (12, "GPT-4", "Oriental Ave", .aiGPT4),
                (15, "GEMINI", "Reading Railroad", .aiGemini),
                (23, "CLAUDE", "Boardwalk", .aiClaude),
                (28, "DEEPSEEK", "Atlantic Ave", .aiDeepSeek),
                (34, "MISTRAL", "Park Place", .aiMistral),
            ]

            ForEach(Array(events.enumerated()), id: \.0) { _, item in
                HStack(spacing: 8) {
                    Text("T\(item.0)")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                        .frame(width: 24)

                    Circle()
                        .fill(item.3)
                        .frame(width: 6, height: 6)

                    Text(item.2)
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.65))
                        .lineLimit(1)

                    Spacer()

                    Text(item.1)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(item.3)
                }
            }
        }
        .padding(12)
        .glassCard(padding: 0, cornerRadius: 8)
    }
}
