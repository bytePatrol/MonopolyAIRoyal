import Foundation
import SwiftUI

// MARK: - Personality

enum AIPersonality: String, Codable, CaseIterable {
    case aggressive   = "AGGRESSIVE"
    case conservative = "CONSERVATIVE"
    case tradeShark   = "TRADE SHARK"
    case mathematical = "MATHEMATICAL"
    case chaoticEvil  = "CHAOTIC EVIL"
    case balanced     = "BALANCED"
}

// MARK: - Player Status

enum PlayerStatus: String, Codable {
    case ready    = "ready"
    case thinking = "thinking"
    case waiting  = "waiting"
    case bankrupt = "bankrupt"
}

// MARK: - Recent Form

enum GameResult: String, Codable {
    case win  = "W"
    case loss = "L"
}

// MARK: - AIPlayer

struct AIPlayer: Identifiable, Codable, Equatable {
    var id: String
    var name: String
    var model: String                       // e.g. "claude-3-5-sonnet-20241022"
    var personality: AIPersonality
    var elo: Double
    var winRate: Double                     // 0-100
    var totalGames: Int
    var colorHex: String                    // e.g. "#7C3AED"
    var recentForm: [GameResult]
    var cash: Int
    var propertyCount: Int
    var hotelCount: Int
    var houseCount: Int
    var netWorth: Int
    var status: PlayerStatus
    var handicap: Int?

    // Personality trait scores (0-100)
    var aggression: Int
    var trading: Int
    var risk: Int
    var efficiency: Int

    // In-game position (board space index 0-39)
    var boardPosition: Int = 0
    var ownedPropertyIDs: [Int] = []
    var jailTurns: Int = 0
    var isInJail: Bool = false
    var getOutOfJailCards: Int = 0
    var isBankrupt: Bool = false

    var color: Color { Color(hex: colorHex) }

    // MARK: - Default AI Players (Mock Data)

    static let mockPlayers: [AIPlayer] = [
        AIPlayer(
            id: "claude", name: "CLAUDE 3.5", model: "anthropic/claude-3-5-sonnet",
            personality: .aggressive, elo: 2847, winRate: 67, totalGames: 43,
            colorHex: "#7C3AED",
            recentForm: [.win, .win, .loss, .win, .win],
            cash: 2450, propertyCount: 8, hotelCount: 2, houseCount: 3,
            netWorth: 5240, status: .ready, handicap: nil,
            aggression: 85, trading: 60, risk: 75, efficiency: 90
        ),
        AIPlayer(
            id: "gpt4", name: "GPT-4", model: "openai/gpt-4-turbo",
            personality: .conservative, elo: 2721, winRate: 62, totalGames: 51,
            colorHex: "#10B981",
            recentForm: [.win, .loss, .win, .win, .loss],
            cash: 3100, propertyCount: 6, hotelCount: 1, houseCount: 4,
            netWorth: 4850, status: .ready, handicap: nil,
            aggression: 40, trading: 70, risk: 30, efficiency: 85
        ),
        AIPlayer(
            id: "gemini", name: "GEMINI PRO", model: "google/gemini-pro-1.5",
            personality: .tradeShark, elo: 2693, winRate: 59, totalGames: 38,
            colorHex: "#06B6D4",
            recentForm: [.win, .win, .win, .loss, .win],
            cash: 1850, propertyCount: 10, hotelCount: 0, houseCount: 6,
            netWorth: 4200, status: .ready, handicap: nil,
            aggression: 55, trading: 95, risk: 60, efficiency: 75
        ),
        AIPlayer(
            id: "deepseek", name: "DEEPSEEK", model: "deepseek/deepseek-chat",
            personality: .mathematical, elo: 2634, winRate: 55, totalGames: 47,
            colorHex: "#F59E0B",
            recentForm: [.loss, .win, .win, .loss, .win],
            cash: 2200, propertyCount: 7, hotelCount: 1, houseCount: 2,
            netWorth: 4100, status: .ready, handicap: -200,
            aggression: 50, trading: 80, risk: 45, efficiency: 95
        ),
        AIPlayer(
            id: "llama", name: "LLAMA 3", model: "meta-llama/llama-3-70b-instruct",
            personality: .chaoticEvil, elo: 2589, winRate: 51, totalGames: 42,
            colorHex: "#EF4444",
            recentForm: [.loss, .loss, .win, .loss, .win],
            cash: 1600, propertyCount: 9, hotelCount: 0, houseCount: 5,
            netWorth: 3800, status: .ready, handicap: nil,
            aggression: 95, trading: 40, risk: 90, efficiency: 55
        ),
        AIPlayer(
            id: "mistral", name: "MISTRAL", model: "mistralai/mistral-large",
            personality: .balanced, elo: 2556, winRate: 48, totalGames: 39,
            colorHex: "#EC4899",
            recentForm: [.win, .loss, .loss, .win, .loss],
            cash: 2800, propertyCount: 5, hotelCount: 1, houseCount: 3,
            netWorth: 4400, status: .ready, handicap: nil,
            aggression: 60, trading: 65, risk: 55, efficiency: 70
        ),
    ]

    // Net worth bar percent (relative to 6000 max)
    var netWorthPercent: Double { min(Double(netWorth) / 6000.0, 1.0) }
}
