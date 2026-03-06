import Foundation

// MARK: - Game Phase

enum GamePhase: String, Codable {
    case setup       = "setup"
    case rolling     = "rolling"
    case moving      = "moving"
    case action      = "action"      // landing on space
    case aiDeciding  = "aiDeciding"  // AI thinking
    case trading     = "trading"
    case building    = "building"
    case gameOver    = "gameOver"
}

// MARK: - Dice Roll

struct DiceRoll: Codable, Equatable {
    var die1: Int
    var die2: Int
    var total: Int { die1 + die2 }
    var isDoubles: Bool { die1 == die2 }

    static func random() -> DiceRoll {
        let d1 = Int.random(in: 1...6)
        let d2 = Int.random(in: 1...6)
        return DiceRoll(die1: d1, die2: d2)
    }
}

// MARK: - GameState

struct GameState: Codable, Equatable {
    var id: String = UUID().uuidString
    var players: [AIPlayer]
    var board: [BoardSpace]
    var currentPlayerIndex: Int = 0
    var turn: Int = 1
    var phase: GamePhase = .rolling
    var lastDiceRoll: DiceRoll?
    var events: [GameEvent] = []
    var startDate: Date = Date()
    var endDate: Date?
    var winnerID: String?
    var doublesCount: Int = 0           // Consecutive doubles
    var freeParkingPot: Int = 0         // If free parking house rule enabled

    var currentPlayer: AIPlayer? {
        guard players.indices.contains(currentPlayerIndex) else { return nil }
        return players[currentPlayerIndex]
    }

    var activePlayers: [AIPlayer] {
        players.filter { !$0.isBankrupt }
    }

    var isGameOver: Bool {
        activePlayers.count <= 1 || phase == .gameOver
    }

    // Snapshot (lightweight copy for Monte Carlo)
    func snapshot() -> GameState { self }

    // Advance to next active player
    mutating func advanceToNextPlayer() {
        doublesCount = 0
        var next = (currentPlayerIndex + 1) % players.count
        var attempts = 0
        while players[next].isBankrupt && attempts < players.count {
            next = (next + 1) % players.count
            attempts += 1
        }
        currentPlayerIndex = next
        turn += 1
        phase = .rolling
    }

    // Get player by ID
    func player(withID id: String) -> AIPlayer? {
        players.first { $0.id == id }
    }

    func playerIndex(withID id: String) -> Int? {
        players.firstIndex { $0.id == id }
    }

    // Properties owned by a player
    func ownedSpaces(for playerID: String) -> [BoardSpace] {
        board.filter { $0.ownerID == playerID }
    }

    // Check if player has a full color group
    func hasMonopoly(playerID: String, group: ColorGroup) -> Bool {
        let groupSpaces = board.filter { $0.colorGroup == group }
        return groupSpaces.allSatisfy { $0.ownerID == playerID }
    }

    // Count owned railroads
    func railroadCount(for playerID: String) -> Int {
        board.filter { BoardSpace.railroadIDs.contains($0.id) && $0.ownerID == playerID }.count
    }

    // Count owned utilities
    func utilityCount(for playerID: String) -> Int {
        board.filter { BoardSpace.utilityIDs.contains($0.id) && $0.ownerID == playerID }.count
    }

    // Net worth calculation
    func calculateNetWorth(for playerID: String) -> Int {
        guard let player = player(withID: playerID) else { return 0 }
        let propertyCash = ownedSpaces(for: playerID).reduce(0) { acc, space in
            let propertyValue = space.isMortgaged
                ? (space.mortgageValue ?? 0)
                : (space.price ?? 0)
            let improvement = (space.hasHotel ? 5 : space.houses) * (space.colorGroup?.houseCost ?? 0)
            return acc + propertyValue + improvement
        }
        return player.cash + propertyCash
    }
}

// MARK: - GameState Factory

extension GameState {
    static func newGame(players: [AIPlayer]) -> GameState {
        var state = GameState(
            players: players,
            board: BoardSpace.allSpaces
        )
        // Give each player starting cash
        for i in state.players.indices {
            state.players[i].cash = 1500
            state.players[i].boardPosition = 0
            state.players[i].ownedPropertyIDs = []
            state.players[i].jailTurns = 0
            state.players[i].isInJail = false
            state.players[i].isBankrupt = false
            state.players[i].status = .waiting
        }
        state.players[0].status = .thinking
        return state
    }

    static func mockState() -> GameState {
        var state = newGame(players: Array(AIPlayer.mockPlayers))
        state.turn = 47
        state.lastDiceRoll = DiceRoll(die1: 4, die2: 5)
        state.phase = .aiDeciding
        // Set some owned properties for visual richness
        state.board[39].ownerID = "claude"   // Boardwalk
        state.board[37].ownerID = "claude"   // Park Place
        state.board[5].ownerID = "gemini"    // Reading Railroad
        state.board[15].ownerID = "gemini"   // Pennsylvania Railroad
        state.board[6].ownerID = "gpt4"
        state.players[0].boardPosition = 39
        state.players[1].boardPosition = 15
        state.players[2].boardPosition = 5
        return state
    }
}
