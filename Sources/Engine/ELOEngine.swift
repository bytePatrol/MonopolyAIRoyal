import Foundation

// MARK: - ELO Engine

enum ELOEngine {
    static let kFactor: Double = 32

    // MARK: - Multi-Player ELO Update

    /// Compute ELO deltas for all players from a game result.
    /// Rankings: 1 = winner, 2 = second, ..., n = last (bankrupt first).
    static func computeDeltas(
        players: [(id: String, elo: Double, rank: Int)]
    ) -> [String: Double] {
        var deltas: [String: Double] = [:]
        for player in players { deltas[player.id] = 0.0 }

        // All pairwise matchups
        let n = players.count
        for i in 0..<n {
            for j in (i+1)..<n {
                let p1 = players[i]
                let p2 = players[j]

                // Actual outcomes based on rank (lower rank = better)
                let s1: Double = p1.rank < p2.rank ? 1.0 : (p1.rank == p2.rank ? 0.5 : 0.0)
                let s2: Double = 1.0 - s1

                // Expected scores
                let e1 = expectedScore(ratingA: p1.elo, ratingB: p2.elo)
                let e2 = 1.0 - e1

                // ELO deltas
                deltas[p1.id]! += kFactor * (s1 - e1)
                deltas[p2.id]! += kFactor * (s2 - e2)
            }
        }
        return deltas
    }

    /// Expected score for player A vs player B.
    static func expectedScore(ratingA: Double, ratingB: Double) -> Double {
        return 1.0 / (1.0 + pow(10.0, (ratingB - ratingA) / 400.0))
    }

    /// Apply deltas to create updated ELO records.
    static func applyDeltas(
        deltas: [String: Double],
        players: [AIPlayer],
        gameID: String,
        ranks: [String: Int]
    ) -> [ELORecord] {
        players.compactMap { player in
            guard let delta = deltas[player.id] else { return nil }
            return ELORecord(
                playerID: player.id,
                model: player.model,
                elo: player.elo + delta,
                delta: delta,
                gameID: gameID,
                rank: ranks[player.id] ?? players.count
            )
        }
    }

    // MARK: - Rank Players from Game State

    static func rankPlayers(from state: GameState) -> [(id: String, elo: Double, rank: Int)] {
        var players = state.players
        // Sort: active players by net worth (desc), then bankrupt by order of bankruptcy
        let active = players.filter { !$0.isBankrupt }.sorted {
            state.calculateNetWorth(for: $0.id) > state.calculateNetWorth(for: $1.id)
        }
        let bankrupt = players.filter { $0.isBankrupt }
        let sorted = active + bankrupt
        return sorted.enumerated().map { (idx, player) in
            (id: player.id, elo: player.elo, rank: idx + 1)
        }
    }

    // MARK: - ELO Category

    static func category(for elo: Double) -> String {
        switch elo {
        case 3000...:     return "Grandmaster"
        case 2700..<3000: return "Elite"
        case 2400..<2700: return "Master"
        case 2100..<2400: return "Expert"
        case 1800..<2100: return "Advanced"
        case 1500..<1800: return "Intermediate"
        default:          return "Novice"
        }
    }
}
