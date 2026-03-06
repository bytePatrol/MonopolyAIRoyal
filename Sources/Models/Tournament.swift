import Foundation

// MARK: - Tournament Format

enum TournamentFormat: String, Codable, CaseIterable {
    case single      = "Single Game"
    case bestOf3     = "Best of 3"
    case bestOf5     = "Best of 5"
    case roundRobin  = "Round Robin"
    case swiss       = "Swiss"
}

// MARK: - Bracket Match

struct BracketMatch: Identifiable, Codable {
    var id: String = UUID().uuidString
    var player1ID: String
    var player2ID: String?           // nil = bye
    var winnerID: String?
    var gameID: String?
    var round: Int
    var matchNumber: Int
}

// MARK: - Series State (Best-of-X)

struct SeriesState: Codable {
    var player1ID: String
    var player2ID: String
    var wins1: Int = 0
    var wins2: Int = 0
    var targetWins: Int           // e.g. 2 for best-of-3
    var gameIDs: [String] = []

    var isComplete: Bool { wins1 >= targetWins || wins2 >= targetWins }
    var leaderID: String? {
        if wins1 > wins2 { return player1ID }
        if wins2 > wins1 { return player2ID }
        return nil
    }
}

// MARK: - Tournament

struct Tournament: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var format: TournamentFormat
    var playerIDs: [String]
    var bracket: [BracketMatch] = []
    var seriesState: SeriesState?
    var schedule: [ScheduledGame] = []
    var currentGameIndex: Int = 0
    var isComplete: Bool = false
    var winnerID: String?
    var createdAt: Date = Date()
}

// MARK: - Scheduled Game

struct ScheduledGame: Identifiable, Codable {
    var id: String = UUID().uuidString
    var tournamentID: String?
    var playerIDs: [String]
    var scheduledAt: Date?
    var autoStart: Bool = false
    var isCompleted: Bool = false
    var gameID: String?
}
