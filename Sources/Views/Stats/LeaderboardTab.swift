import SwiftUI
import Charts

struct LeaderboardTab: View {
    @Environment(StatsViewModel.self) private var vm
    @State private var sortKey: StatsViewModel.LeaderboardSortKey = .elo

    var body: some View {
        VStack(spacing: 0) {
            // Sort bar
            sortBar

            HStack(spacing: 0) {
                // ELO Table
                eloTable
                    .frame(maxWidth: .infinity)

                Divider().background(Color.cardBorder)

                // H2H Matrix
                h2hMatrix
                    .frame(width: 320)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Sort Bar

    private var sortBar: some View {
        HStack {
            Text("SORT BY:")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))

            ForEach([
                ("ELO", StatsViewModel.LeaderboardSortKey.elo),
                ("GAMES", .games),
                ("WIN RATE", .winRate),
                ("WINS", .wins),
            ], id: \.0) { label, key in
                Button {
                    sortKey = key
                    vm.sortLeaderboard(by: key)
                } label: {
                    Text(label)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(sortKey == key ? .neonViolet : .white.opacity(0.4))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(sortKey == key ? Color.neonViolet.opacity(0.1) : Color.clear)
                        .cornerRadius(5)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(sortKey == key ? Color.neonViolet.opacity(0.3) : Color.clear, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(Color.cardBackground)
        .overlay(Rectangle().fill(Color.cardBorder).frame(height: 1), alignment: .bottom)
    }

    // MARK: - ELO Table

    private var eloTable: some View {
        VStack(spacing: 0) {
            // Column headers
            HStack {
                Text("RANK")
                    .frame(width: 40, alignment: .center)
                Text("PLAYER")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("ELO")
                    .frame(width: 60, alignment: .trailing)
                Text("GAMES")
                    .frame(width: 55, alignment: .trailing)
                Text("WINS")
                    .frame(width: 45, alignment: .trailing)
                Text("WIN%")
                    .frame(width: 50, alignment: .trailing)
                Text("TREND")
                    .frame(width: 80, alignment: .trailing)
            }
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.3))
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.02))
            .overlay(Rectangle().fill(Color.cardBorder).frame(height: 1), alignment: .bottom)

            // Rows
            ScrollView {
                ForEach(Array(vm.leaderboard.enumerated()), id: \.1.id) { idx, entry in
                    LeaderboardRow(entry: entry, rank: idx + 1)
                }
            }
        }
    }

    // MARK: - H2H Matrix

    private var h2hMatrix: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("HEAD-TO-HEAD MATRIX")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))

                let players = AIPlayer.mockPlayers

                // Column labels
                HStack(spacing: 0) {
                    Text("")
                        .frame(width: 60)
                    ForEach(players) { p in
                        Text(String(p.name.prefix(4)))
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundStyle(p.color)
                            .frame(width: 40, alignment: .center)
                    }
                }
                .padding(.bottom, 4)

                ForEach(players) { rowPlayer in
                    HStack(spacing: 0) {
                        // Row label
                        Text(rowPlayer.name.prefix(6))
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(rowPlayer.color)
                            .frame(width: 60, alignment: .leading)
                            .lineLimit(1)

                        // Cells
                        ForEach(players) { colPlayer in
                            matrixCell(row: rowPlayer, col: colPlayer)
                                .frame(width: 40, height: 32)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color.appBackground)
    }

    private func matrixCell(row: AIPlayer, col: AIPlayer) -> some View {
        if row.id == col.id {
            return AnyView(
                Rectangle()
                    .fill(Color.white.opacity(0.04))
                    .cornerRadius(3)
                    .padding(1)
            )
        }

        let entry = vm.h2hMatrix.first {
            ($0.player1ID == row.id && $0.player2ID == col.id) ||
            ($0.player1ID == col.id && $0.player2ID == row.id)
        }

        let winRate: Double
        let wins: Int
        if let e = entry {
            if e.player1ID == row.id {
                winRate = e.winRate1
                wins = e.winsBy1
            } else {
                winRate = 1 - e.winRate1
                wins = e.winsBy2
            }
        } else {
            winRate = 0.5
            wins = 0
        }

        let bgColor = winRate >= 0.6 ? Color.neonGreen :
                      winRate <= 0.4 ? Color.neonRed :
                      Color.neonAmber

        return AnyView(
            VStack(spacing: 1) {
                Text("\(wins)")
                    .font(.system(size: 11, weight: .black, design: .monospaced))
                    .foregroundStyle(bgColor)
                Text(String(format: "%.0f%%", winRate * 100))
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(bgColor.opacity(0.08))
            .cornerRadius(3)
            .padding(1)
        )
    }
}

// MARK: - Leaderboard Row

struct LeaderboardRow: View {
    let entry: ELOLeaderboardEntry
    let rank: Int

    var body: some View {
        HStack {
            // Rank
            ZStack {
                if rank == 1 {
                    Text("🏆")
                        .font(.system(size: 14))
                } else {
                    Text("\(rank)")
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            .frame(width: 40, alignment: .center)

            // Player name + badge
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: entry.colorHex))
                    .frame(width: 10, height: 10)
                    .neonGlow(color: Color(hex: entry.colorHex), radius: 4)
                Text(entry.playerName)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // ELO
            Text("\(Int(entry.currentELO))")
                .font(.system(size: 13, weight: .black, design: .monospaced))
                .foregroundStyle(Color(hex: entry.colorHex))
                .frame(width: 60, alignment: .trailing)

            // Games
            Text("\(entry.totalGames)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .frame(width: 55, alignment: .trailing)

            // Wins
            Text("\(entry.wins)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.neonGreen.opacity(0.8))
                .frame(width: 45, alignment: .trailing)

            // Win rate
            Text(String(format: "%.1f%%", entry.winRate))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 50, alignment: .trailing)

            // Sparkline
            miniSparkline
                .frame(width: 80, height: 20)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(rank == 1 ? Color(hex: entry.colorHex).opacity(0.06) : Color.clear)
        .overlay(Rectangle().fill(Color.cardBorder).frame(height: 0.5), alignment: .bottom)
    }

    private var miniSparkline: some View {
        GeometryReader { geo in
            let pts = entry.eloHistory
            let mn = (pts.min() ?? 0)
            let mx = (pts.max() ?? 1)
            let range = max(mx - mn, 1)
            Path { path in
                for (i, v) in pts.enumerated() {
                    let x = geo.size.width * CGFloat(i) / CGFloat(max(pts.count - 1, 1))
                    let y = geo.size.height * (1 - CGFloat((v - mn) / range))
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(Color(hex: entry.colorHex).opacity(0.7), lineWidth: 1.5)
        }
    }
}
