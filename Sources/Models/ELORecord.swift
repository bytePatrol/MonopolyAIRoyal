import Foundation

// MARK: - ELO Record

struct ELORecord: Identifiable, Codable {
    var id: String = UUID().uuidString
    var playerID: String
    var model: String
    var elo: Double
    var delta: Double
    var gameID: String
    var rank: Int               // Final rank in game (1 = winner)
    var date: Date = Date()
}

// MARK: - ELO Leaderboard Entry

struct ELOLeaderboardEntry: Identifiable {
    var id: String { playerID }
    var playerID: String
    var playerName: String
    var colorHex: String
    var currentELO: Double
    var totalGames: Int
    var wins: Int
    var winRate: Double { totalGames > 0 ? Double(wins) / Double(totalGames) * 100 : 0 }
    var eloHistory: [Double]   // Last N ELO values for sparkline

    static let mock: [ELOLeaderboardEntry] = AIPlayer.mockPlayers.map { p in
        ELOLeaderboardEntry(
            playerID: p.id,
            playerName: p.name,
            colorHex: p.colorHex,
            currentELO: p.elo,
            totalGames: p.totalGames,
            wins: Int(Double(p.totalGames) * p.winRate / 100.0),
            eloHistory: (0..<10).map { _ in p.elo + Double.random(in: -100...100) }
        )
    }
}
