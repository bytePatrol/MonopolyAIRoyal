import Foundation

// MARK: - Monte Carlo Engine

actor MonteCarloEngine {
    private let simulationCount: Int

    init(simulationCount: Int = 10_000) {
        self.simulationCount = simulationCount
    }

    // MARK: - Win Probability Estimation

    /// Simulate `simulationCount` games from current state.
    /// Returns a dictionary: [playerID: winProbability (0.0-1.0)]
    func estimateWinProbabilities(from state: GameState) async -> [String: Double] {
        var winCounts: [String: Int] = [:]
        for player in state.players { winCounts[player.id] = 0 }

        let activePlayers = state.activePlayers
        guard activePlayers.count > 1 else {
            if let sole = activePlayers.first {
                winCounts[sole.id] = simulationCount
            }
            return normalize(winCounts, total: simulationCount)
        }

        // Run simulations
        for _ in 0..<simulationCount {
            var simState = state.snapshot()
            let winnerID = runFastSimulation(state: &simState)
            if let winner = winnerID {
                winCounts[winner, default: 0] += 1
            }
        }

        return normalize(winCounts, total: simulationCount)
    }

    // MARK: - Fast Simulation (Simplified Monopoly)

    private func runFastSimulation(state: inout GameState) -> String? {
        var turnLimit = 150
        var safetyLimit = 500

        while !state.isGameOver && turnLimit > 0 && safetyLimit > 0 {
            guard let currentPlayer = state.currentPlayer else { break }
            turnLimit -= 1
            safetyLimit -= 1

            // Roll dice
            let roll = DiceRoll.random()
            let newPosition = (currentPlayer.boardPosition + roll.total) % 40

            if let idx = state.playerIndex(withID: currentPlayer.id) {
                // Collect Go salary
                if newPosition < state.players[idx].boardPosition {
                    state.players[idx].cash += BoardSpace.goSalary
                }
                state.players[idx].boardPosition = newPosition

                // Handle space
                let space = state.board[newPosition]
                fastHandleLanding(state: &state, playerIndex: idx, space: space, diceTotal: roll.total)

                // Check bankruptcy
                if state.players[idx].cash < 0 {
                    state.players[idx].isBankrupt = true
                    state.players[idx].cash = 0
                    // Remove their properties
                    for si in state.board.indices where state.board[si].ownerID == currentPlayer.id {
                        state.board[si].ownerID = nil
                    }
                }
            }

            state.advanceToNextPlayer()
        }

        // Determine winner by net worth
        let active = state.activePlayers
        if active.count == 1 { return active.first?.id }
        return active.max(by: { state.calculateNetWorth(for: $0.id) < state.calculateNetWorth(for: $1.id) })?.id
    }

    private func fastHandleLanding(state: inout GameState, playerIndex: Int, space: BoardSpace, diceTotal: Int) {
        let player = state.players[playerIndex]

        switch space.type {
        case .property, .railroad, .utility:
            if let ownerID = space.ownerID, ownerID != player.id, !space.isMortgaged {
                let rent = MonopolyRules.rent(for: space, in: state, diceTotal: diceTotal)
                state.players[playerIndex].cash -= rent
                if let ownerIdx = state.playerIndex(withID: ownerID) {
                    state.players[ownerIdx].cash += rent
                }
            } else if space.ownerID == nil, let price = space.price {
                // Personality-weighted buy decision
                let buyThreshold: Double
                switch player.personality {
                case .aggressive, .chaoticEvil: buyThreshold = 0.3
                case .conservative:             buyThreshold = 0.7
                case .mathematical:             buyThreshold = 0.5
                case .tradeShark:               buyThreshold = 0.4
                case .balanced:                 buyThreshold = 0.5
                }
                if player.cash >= price && Double.random(in: 0...1) > buyThreshold {
                    state.players[playerIndex].cash -= price
                    state.board[space.id].ownerID = player.id
                }
            }

        case .corner:
            if space.id == 30 { // Go To Jail
                state.players[playerIndex].isInJail = true
                state.players[playerIndex].boardPosition = 10
            }

        case .tax:
            let tax = space.id == 4 ? min(200, Int(Double(player.cash) * 0.1)) : 100
            state.players[playerIndex].cash -= tax

        default:
            break
        }
    }

    // MARK: - Helpers

    private func normalize(_ counts: [String: Int], total: Int) -> [String: Double] {
        guard total > 0 else { return counts.mapValues { _ in 0.0 } }
        return counts.mapValues { Double($0) / Double(total) }
    }
}

// MARK: - Win Probability History Point

struct WinProbabilityPoint {
    var turn: Int
    var probabilities: [String: Double]
}
