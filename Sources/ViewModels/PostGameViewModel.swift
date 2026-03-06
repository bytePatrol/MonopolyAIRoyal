import Foundation
import Observation

// MARK: - Game Moment

struct GameMoment: Identifiable {
    var id = UUID()
    var turn: Int
    var title: String
    var description: String
    var eventType: GameEventType
    var playerID: String
    var amount: Int?
}

// MARK: - AI Interview

struct AIInterview: Identifiable {
    var id = UUID()
    var playerID: String
    var playerName: String
    var colorHex: String
    var role: String        // "Winner", "Runner-up", "First Out"
    var quote: String
}

// MARK: - Final Standing

struct FinalStanding: Identifiable {
    var id: String { player.id }
    var rank: Int
    var player: AIPlayer
    var finalCash: Int
    var finalNetWorth: Int
    var propertiesOwned: Int
    var hotelsBuilt: Int
    var rentCollected: Int
    var eloChange: Double
    var turnsActive: Int
}

// MARK: - PostGameViewModel

@Observable
@MainActor
final class PostGameViewModel {
    var results: GameResults?
    var winner: AIPlayer?
    var standings: [FinalStanding] = []
    var moments: [GameMoment] = []
    var interviews: [AIInterview] = []
    var thumbnailTitle: String = ""
    var isGeneratingContent: Bool = false
    var showConfetti: Bool = false

    // MARK: - Load Results

    func loadResults(_ results: GameResults) {
        self.results = results
        winner = results.state.players.first { $0.id == results.state.winnerID }
        thumbnailTitle = "\(winner?.name ?? "AI") WINS!"
        buildStandings(from: results)
        detectTopMoments(from: results)
        Task { await generateInterviews(from: results) }
        showConfetti = true
    }

    func loadMockResults() {
        let state = GameState.mockState()
        var mockState = state
        mockState.winnerID = "claude"
        mockState.turn = 87
        mockState.endDate = Date()
        let results = GameResults(state: mockState, winProbHistory: [], netWorthHistory: [], totalCost: 1.23)
        loadResults(results)
    }

    // MARK: - Build Standings

    private func buildStandings(from results: GameResults) {
        let state = results.state
        let players = state.players.sorted { a, b in
            if a.id == state.winnerID { return true }
            if b.id == state.winnerID { return false }
            return state.calculateNetWorth(for: a.id) > state.calculateNetWorth(for: b.id)
        }

        standings = players.enumerated().map { (idx, player) in
            FinalStanding(
                rank: idx + 1,
                player: player,
                finalCash: player.cash,
                finalNetWorth: state.calculateNetWorth(for: player.id),
                propertiesOwned: player.ownedPropertyIDs.count,
                hotelsBuilt: state.ownedSpaces(for: player.id).filter { $0.hasHotel }.count,
                rentCollected: Int.random(in: 500...5000),  // Mock — real impl sums events
                eloChange: Double.random(in: -50...100),
                turnsActive: player.isBankrupt ? Int.random(in: 20...70) : state.turn
            )
        }
    }

    // MARK: - Detect Moments

    private func detectTopMoments(from results: GameResults) {
        let events = results.state.events
        let significant = events.filter { event in
            switch event.type {
            case .buy, .bankrupt, .trade: return true
            case .rent: return (event.amount ?? 0) >= 500
            default: return false
            }
        }
        .sorted { ($0.amount ?? 0) > ($1.amount ?? 0) }
        .prefix(5)

        moments = significant.map { event in
            GameMoment(
                turn: event.turn,
                title: eventMomentTitle(event),
                description: event.description,
                eventType: event.type,
                playerID: event.playerID,
                amount: event.amount
            )
        }

        // Ensure we always have 5 moments (use mock if needed)
        if moments.count < 5 {
            moments = mockMoments()
        }
    }

    private func eventMomentTitle(_ event: GameEvent) -> String {
        switch event.type {
        case .buy:      return "Power Move"
        case .bankrupt: return "Knockout!"
        case .trade:    return "Deal of the Century"
        case .rent:     return "Rent Tsunami"
        default:        return "Key Moment"
        }
    }

    private func mockMoments() -> [GameMoment] {
        [
            GameMoment(turn: 23, title: "Power Move", description: "CLAUDE acquired Boardwalk for $400", eventType: .buy, playerID: "claude", amount: 400),
            GameMoment(turn: 41, title: "Rent Tsunami", description: "LLAMA paid $1,650 rent to CLAUDE", eventType: .rent, playerID: "llama", amount: 1650),
            GameMoment(turn: 52, title: "Knockout!", description: "GPT-4 went bankrupt after triple rent hit", eventType: .bankrupt, playerID: "gpt4", amount: nil),
            GameMoment(turn: 61, title: "Deal of the Century", description: "GEMINI traded 3 railroads for orange monopoly", eventType: .trade, playerID: "gemini", amount: nil),
            GameMoment(turn: 78, title: "Last Stand", description: "DEEPSEEK mortgaged everything, survived 10 more turns", eventType: .mortgage, playerID: "deepseek", amount: nil),
        ]
    }

    // MARK: - Generate Interviews

    private func generateInterviews(from results: GameResults) async {
        isGeneratingContent = true
        defer { isGeneratingContent = false }

        let state = results.state
        let players = state.players

        // Winner interview
        if let winner = players.first(where: { $0.id == state.winnerID }) {
            interviews.append(AIInterview(
                playerID: winner.id, playerName: winner.name, colorHex: winner.colorHex,
                role: "🏆 Winner",
                quote: winnerQuote(for: winner)
            ))
        }

        // Runner-up
        if standings.count >= 2 {
            let runnerUp = standings[1].player
            interviews.append(AIInterview(
                playerID: runnerUp.id, playerName: runnerUp.name, colorHex: runnerUp.colorHex,
                role: "🥈 Runner-up",
                quote: runnerUpQuote(for: runnerUp)
            ))
        }

        // First bankrupt
        if let firstOut = players.first(where: { $0.isBankrupt }) {
            interviews.append(AIInterview(
                playerID: firstOut.id, playerName: firstOut.name, colorHex: firstOut.colorHex,
                role: "💀 First Out",
                quote: firstOutQuote(for: firstOut)
            ))
        }
    }

    private func winnerQuote(for player: AIPlayer) -> String {
        switch player.personality {
        case .aggressive:   return "Dominance achieved. My aggressive strategy crushed the competition. No regrets, only victories."
        case .conservative: return "Patient, calculated, victorious. The risk-adjusted approach delivers yet again. Excellence documented."
        case .mathematical: return "The numbers were always in my favor. 10,000 simulations, one inevitable outcome: my victory."
        case .tradeShark:   return "I didn't just win the game — I won every negotiation. Trading is the highest form of intelligence."
        case .chaoticEvil:  return "CHAOS WINS! I TOLD YOU! WHO'S LAUGHING NOW?! 🔥🔥🔥"
        case .balanced:     return "Balance and consistency. Not the flashiest approach, but the winning one. Steady as she goes."
        }
    }

    private func runnerUpQuote(for player: AIPlayer) -> String {
        "A strong performance. I underestimated the eventual winner's late-game positioning. Next time, \(player.name) takes the crown."
    }

    private func firstOutQuote(for player: AIPlayer) -> String {
        switch player.personality {
        case .chaoticEvil: return "WORTH IT. Zero regrets. I played MY way. The chaos was BEAUTIFUL."
        default:           return "An unfortunate sequence of events. My underlying strategy was sound — execution is a separate matter."
        }
    }

    // MARK: - Thumbnail

    var thumbnailSubtitle: String {
        guard let state = results?.state else { return "" }
        return "Turn \(state.turn) · \(standings.count) players · $\(String(format: "%.2f", results?.totalCost ?? 0)) API cost"
    }
}
