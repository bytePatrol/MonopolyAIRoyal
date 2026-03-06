import SwiftUI

struct FinalStandingsTable: View {
    let standings: [FinalStanding]
    @State private var sortColumn: SortColumn = .rank
    @State private var sortAscending: Bool = true

    enum SortColumn: String, CaseIterable {
        case rank       = "RANK"
        case player     = "PLAYER"
        case cash       = "CASH"
        case netWorth   = "NET WORTH"
        case properties = "PROPS"
        case hotels     = "HOTELS"
        case rent       = "RENT"
        case elo        = "ELO ±"
        case turns      = "TURNS"
    }

    var sortedStandings: [FinalStanding] {
        standings.sorted { a, b in
            let cmp: Bool
            switch sortColumn {
            case .rank:       cmp = a.rank < b.rank
            case .player:     cmp = a.player.name < b.player.name
            case .cash:       cmp = a.finalCash > b.finalCash
            case .netWorth:   cmp = a.finalNetWorth > b.finalNetWorth
            case .properties: cmp = a.propertiesOwned > b.propertiesOwned
            case .hotels:     cmp = a.hotelsBuilt > b.hotelsBuilt
            case .rent:       cmp = a.rentCollected > b.rentCollected
            case .elo:        cmp = a.eloChange > b.eloChange
            case .turns:      cmp = a.turnsActive > b.turnsActive
            }
            return sortAscending ? cmp : !cmp
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("FINAL STANDINGS")
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                Text("COMPLETE GAME STATISTICS")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }

            VStack(spacing: 0) {
                // Column headers
                headerRow

                // Data rows
                ForEach(sortedStandings) { standing in
                    StandingRow(standing: standing)
                }
            }
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cardBorder, lineWidth: 1))
        }
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            ForEach(SortColumn.allCases, id: \.self) { col in
                headerCell(col)
            }
        }
        .background(Color.white.opacity(0.03))
        .overlay(Rectangle().fill(Color.cardBorder).frame(height: 1), alignment: .bottom)
    }

    private func headerCell(_ col: SortColumn) -> some View {
        Button {
            if sortColumn == col {
                sortAscending.toggle()
            } else {
                sortColumn = col
                sortAscending = true
            }
        } label: {
            HStack(spacing: 3) {
                Text(col.rawValue)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(sortColumn == col ? .neonViolet : .white.opacity(0.3))
                if sortColumn == col {
                    Image(systemName: sortAscending ? "chevron.up" : "chevron.down")
                        .font(.system(size: 7))
                        .foregroundStyle(.neonViolet)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Standing Row

struct StandingRow: View {
    let standing: FinalStanding

    var body: some View {
        HStack(spacing: 0) {
            // Rank
            rankCell

            // Player
            playerCell

            // Cash
            numberCell("$\(standing.finalCash.formatted())", color: .neonGreen)

            // Net worth
            numberCell("$\(standing.finalNetWorth.formatted())", color: standing.player.color)

            // Properties
            numberCell("\(standing.propertiesOwned)", color: .neonCyan)

            // Hotels
            numberCell("\(standing.hotelsBuilt)", color: .neonAmber)

            // Rent
            numberCell("$\(standing.rentCollected.formatted())", color: .neonPink)

            // ELO change
            let eloPos = standing.eloChange >= 0
            numberCell(
                "\(eloPos ? "+" : "")\(Int(standing.eloChange))",
                color: eloPos ? .neonGreen : .neonRed
            )

            // Turns
            numberCell("\(standing.turnsActive)", color: .white.opacity(0.5))
        }
        .overlay(
            Rectangle()
                .fill(standing.player.color)
                .frame(width: 3),
            alignment: .leading
        )
        .overlay(Rectangle().fill(Color.cardBorder).frame(height: 0.5), alignment: .bottom)
        .background(standing.rank == 1 ? standing.player.color.opacity(0.06) : Color.clear)
    }

    private var rankCell: some View {
        ZStack {
            if standing.rank == 1 {
                Text("🏆")
                    .font(.system(size: 16))
            } else {
                Text("\(standing.rank)")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(.white.opacity(standing.player.isBankrupt ? 0.3 : 0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }

    private var playerCell: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(standing.player.color)
                .frame(width: 8, height: 8)
                .neonGlow(color: standing.player.color, radius: 4)
            Text(standing.player.name)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(standing.player.isBankrupt ? .white.opacity(0.3) : .white.opacity(0.85))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
    }

    private func numberCell(_ value: String, color: Color) -> some View {
        Text(value)
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(color.opacity(standing.player.isBankrupt ? 0.3 : 1.0))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 4)
            .padding(.vertical, 10)
    }
}
