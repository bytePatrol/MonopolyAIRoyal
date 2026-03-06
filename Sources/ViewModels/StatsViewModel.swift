import Foundation
import Observation

// MARK: - Chart Series

struct ChartSeries: Identifiable {
    var id: String { playerID }
    var playerID: String
    var playerName: String
    var colorHex: String
    var dataPoints: [ChartPoint]
}

struct ChartPoint: Identifiable {
    var id: String = UUID().uuidString
    var x: Double
    var y: Double
    var label: String = ""
}

// MARK: - H2H Matrix Entry

struct H2HEntry: Identifiable {
    var id: String { "\(player1ID)-\(player2ID)" }
    var player1ID: String
    var player2ID: String
    var winsBy1: Int
    var winsBy2: Int
    var winRate1: Double {
        let total = winsBy1 + winsBy2
        return total > 0 ? Double(winsBy1) / Double(total) : 0.5
    }
}

// MARK: - Storyline

struct Storyline: Identifiable {
    var id = UUID()
    var title: String
    var description: String
    var type: StorylineType
    enum StorylineType { case rivalry, dominance, comeback, streak }
}

// MARK: - StatsViewModel

@Observable
@MainActor
final class StatsViewModel {
    var leaderboard: [ELOLeaderboardEntry] = ELOLeaderboardEntry.mock
    var selectedTab: StatsTab = .winProbability
    var winProbSeries: [ChartSeries] = []
    var cashFlowSeries: [ChartSeries] = []
    var h2hMatrix: [H2HEntry] = []
    var storylines: [Storyline] = []
    var isLoading: Bool = false

    enum StatsTab: String, CaseIterable {
        case winProbability = "Win Probability"
        case cashFlow       = "Cash Flow"
        case propertyMap    = "Property Map"
        case leaderboard    = "Leaderboard"

        var systemImage: String {
            switch self {
            case .winProbability: return "chart.line.uptrend.xyaxis"
            case .cashFlow:       return "chart.bar.fill"
            case .propertyMap:    return "map.fill"
            case .leaderboard:    return "list.number"
            }
        }
    }

    init() {
        generateMockData()
    }

    // MARK: - Refresh from Game Data

    func refreshData(from history: [NetWorthPoint] = []) {
        Task {
            isLoading = true
            defer { isLoading = false }
            if history.isEmpty {
                generateMockData()
            } else {
                buildCashFlowSeries(from: history)
            }
            buildH2HMatrix()
            buildStorylines()
        }
    }

    // MARK: - Mock Data Generation

    private func generateMockData() {
        buildMockWinProbSeries()
        buildMockCashFlowSeries()
        buildH2HMatrix()
        buildStorylines()
    }

    private func buildMockWinProbSeries() {
        let players = AIPlayer.mockPlayers
        let turns = 50
        let n = Double(players.count)

        // Strength bias from ELO — higher ELO = slightly positive drift
        let maxELO = players.map(\.elo).max() ?? 2800
        let minELO = players.map(\.elo).min() ?? 2500
        let eloRange = max(maxELO - minELO, 1)
        let strengths: [Double] = players.map { p in
            // Map ELO to a bias in [-0.012, +0.012]
            ((p.elo - minELO) / eloRange - 0.5) * 0.024
        }

        // Initialize raw scores (unnormalized) — all start equal
        var scores = Array(repeating: 1.0 / n, count: players.count)
        // Store points per player
        var allPoints: [[ChartPoint]] = players.map { _ in [] }

        // Record turn 0
        for i in 0..<players.count {
            allPoints[i].append(ChartPoint(x: 0, y: scores[i] * 100))
        }

        for turn in 1...turns {
            let progress = Double(turn) / Double(turns) // 0→1
            // Noise decreases as game converges: large early, small late
            let noiseScale = 0.06 * (1.0 - progress * 0.7)

            for i in 0..<players.count {
                let noise = Double.random(in: -noiseScale...noiseScale)
                // Drift toward strength bias increases over time
                let drift = strengths[i] * (0.5 + progress * 1.5)
                scores[i] += drift + noise
                scores[i] = max(0.005, scores[i]) // floor to prevent negatives
            }

            // Normalize so all probabilities sum to 100%
            let total = scores.reduce(0, +)
            for i in 0..<players.count {
                scores[i] /= total
                allPoints[i].append(ChartPoint(x: Double(turn), y: scores[i] * 100))
            }
        }

        winProbSeries = players.enumerated().map { (i, player) in
            ChartSeries(playerID: player.id, playerName: player.name,
                        colorHex: player.colorHex, dataPoints: allPoints[i])
        }
    }

    private func buildMockCashFlowSeries() {
        let players = AIPlayer.mockPlayers
        let turns = 50
        cashFlowSeries = players.map { player in
            var cash: Double = 1500
            let points = (0...turns).map { turn -> ChartPoint in
                cash += Double.random(in: -200...400)
                cash = max(0, cash)
                return ChartPoint(x: Double(turn), y: cash)
            }
            return ChartSeries(playerID: player.id, playerName: player.name,
                               colorHex: player.colorHex, dataPoints: points)
        }
    }

    private func buildCashFlowSeries(from history: [NetWorthPoint]) {
        let grouped = Dictionary(grouping: history) { $0.playerID }
        cashFlowSeries = grouped.map { (playerID, points) in
            let player = AIPlayer.mockPlayers.first { $0.id == playerID }
            let chartPoints = points.map { ChartPoint(x: Double($0.turn), y: $0.netWorth) }
            return ChartSeries(
                playerID: playerID,
                playerName: player?.name ?? playerID,
                colorHex: player?.colorHex ?? "#888888",
                dataPoints: chartPoints
            )
        }
    }

    private func buildH2HMatrix() {
        let players = AIPlayer.mockPlayers
        h2hMatrix = []
        for i in 0..<players.count {
            for j in (i+1)..<players.count {
                let w1 = Int.random(in: 3...15)
                let w2 = Int.random(in: 3...15)
                h2hMatrix.append(H2HEntry(
                    player1ID: players[i].id, player2ID: players[j].id,
                    winsBy1: w1, winsBy2: w2
                ))
            }
        }
    }

    private func buildStorylines() {
        storylines = [
            Storyline(title: "Claude's Reign",
                      description: "Claude has won 8 of the last 12 games, establishing dominant control of dark blue properties.",
                      type: .dominance),
            Storyline(title: "The GPT-Gemini Rivalry",
                      description: "GPT-4 vs Gemini: 18 head-to-head matches with a near-perfect 9-9 split. The ultimate balanced rivalry.",
                      type: .rivalry),
            Storyline(title: "DeepSeek's Comeback",
                      description: "After 5 consecutive losses, DeepSeek has won the last 3 games with mathematical precision.",
                      type: .comeback),
            Storyline(title: "LLaMA's Losing Streak",
                      description: "LLaMA's chaotic strategy has resulted in 4 consecutive bankruptcies. Volatility at its finest.",
                      type: .streak),
        ]
    }

    // MARK: - Sort Leaderboard

    func sortLeaderboard(by key: LeaderboardSortKey) {
        switch key {
        case .elo:       leaderboard.sort { $0.currentELO > $1.currentELO }
        case .games:     leaderboard.sort { $0.totalGames > $1.totalGames }
        case .winRate:   leaderboard.sort { $0.winRate > $1.winRate }
        case .wins:      leaderboard.sort { $0.wins > $1.wins }
        }
    }

    enum LeaderboardSortKey {
        case elo, games, winRate, wins
    }
}
