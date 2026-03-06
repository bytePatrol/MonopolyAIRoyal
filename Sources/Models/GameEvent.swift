import Foundation

// MARK: - Game Event Types

enum GameEventType: String, Codable {
    case roll     = "roll"
    case buy      = "buy"
    case trade    = "trade"
    case rent     = "rent"
    case bankrupt = "bankrupt"
    case jail     = "jail"
    case card     = "card"
    case tax      = "tax"
    case build    = "build"
    case mortgage = "mortgage"
}

// MARK: - GameEvent

struct GameEvent: Identifiable, Codable, Equatable {
    var id: String = UUID().uuidString
    var gameID: String
    var turn: Int
    var type: GameEventType
    var description: String
    var playerID: String
    var playerName: String
    var amount: Int?
    var targetPlayerID: String?
    var timestamp: Date = Date()

    // Convenience init
    static func make(
        gameID: String,
        turn: Int,
        type: GameEventType,
        description: String,
        playerID: String,
        playerName: String,
        amount: Int? = nil,
        targetPlayerID: String? = nil
    ) -> GameEvent {
        GameEvent(
            gameID: gameID, turn: turn, type: type,
            description: description, playerID: playerID,
            playerName: playerName, amount: amount,
            targetPlayerID: targetPlayerID
        )
    }

    // Emoji for event feed
    var emoji: String {
        switch type {
        case .roll:     return "🎲"
        case .buy:      return "🏠"
        case .trade:    return "🤝"
        case .rent:     return "💰"
        case .bankrupt: return "💀"
        case .jail:     return "🔒"
        case .card:     return "🃏"
        case .tax:      return "🏛"
        case .build:    return "🏗"
        case .mortgage: return "📋"
        }
    }

    // Badge color key for display
    var colorKey: String {
        switch type {
        case .buy:      return "cyan"
        case .trade:    return "violet"
        case .rent:     return "amber"
        case .bankrupt: return "red"
        case .jail:     return "orange"
        case .card:     return "pink"
        case .tax:      return "red"
        case .build:    return "green"
        case .mortgage: return "gray"
        case .roll:     return "white"
        }
    }
}

// MARK: - Mock Events

extension GameEvent {
    static func mockEvents(gameID: String) -> [GameEvent] {
        [
            make(gameID: gameID, turn: 45, type: .buy,
                 description: "CLAUDE bought Boardwalk", playerID: "claude", playerName: "CLAUDE 3.5", amount: 400),
            make(gameID: gameID, turn: 46, type: .trade,
                 description: "GEMINI ↔ GPT-4 traded railroads", playerID: "gemini", playerName: "GEMINI PRO"),
            make(gameID: gameID, turn: 47, type: .rent,
                 description: "LLAMA paid $850 rent to CLAUDE", playerID: "llama", playerName: "LLAMA 3", amount: 850, targetPlayerID: "claude"),
        ]
    }
}
