import Foundation
import GRDB

// MARK: - Database Service

final class DatabaseService {
    static let shared = DatabaseService()

    private var dbQueue: DatabaseQueue?

    private init() {
        setupDatabase()
    }

    // MARK: - Setup

    private func setupDatabase() {
        do {
            let appSupport = try FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("MonopolyAIRoyal", isDirectory: true)

            try FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
            let dbPath = appSupport.appendingPathComponent("monopoly.sqlite").path

            var config = Configuration()
            config.foreignKeysEnabled = true
            dbQueue = try DatabaseQueue(path: dbPath, configuration: config)

            try runMigrations()
        } catch {
            print("[DatabaseService] Setup failed: \(error)")
        }
    }

    // MARK: - Migrations

    private func runMigrations() throws {
        guard let dbQueue else { return }

        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1_initial") { db in
            try db.create(table: "games", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("startDate", .double).notNull()
                t.column("endDate", .double)
                t.column("format", .text).notNull()
                t.column("winnerId", .text)
                t.column("turns", .integer).notNull().defaults(to: 0)
                t.column("replayJSON", .text)
            }

            try db.create(table: "elo_records", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("playerId", .text).notNull().indexed()
                t.column("model", .text).notNull()
                t.column("elo", .double).notNull()
                t.column("delta", .double).notNull()
                t.column("gameId", .text).notNull()
                t.column("rank", .integer).notNull()
                t.column("date", .double).notNull()
            }

            try db.create(table: "game_events", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("gameId", .text).notNull().indexed()
                t.column("turn", .integer).notNull()
                t.column("type", .text).notNull()
                t.column("playerId", .text).notNull()
                t.column("playerName", .text).notNull()
                t.column("amount", .integer)
                t.column("description", .text).notNull()
                t.column("timestamp", .double).notNull()
            }

            try db.create(table: "api_usage", ifNotExists: true) { t in
                t.primaryKey("id", .text)
                t.column("gameId", .text).notNull().indexed()
                t.column("model", .text).notNull()
                t.column("tokens", .integer).notNull()
                t.column("cost", .double).notNull()
                t.column("date", .double).notNull()
            }

            try db.create(table: "settings", ifNotExists: true) { t in
                t.primaryKey("key", .text)
                t.column("value", .text).notNull()
            }
        }

        try migrator.migrate(dbQueue)
    }

    // MARK: - Games

    func saveGame(_ state: GameState) {
        guard let dbQueue else { return }
        try? dbQueue.write { db in
            try db.execute(
                sql: """
                INSERT OR REPLACE INTO games (id, startDate, endDate, format, winnerId, turns)
                VALUES (?, ?, ?, ?, ?, ?)
                """,
                arguments: [
                    state.id,
                    state.startDate.timeIntervalSince1970,
                    state.endDate?.timeIntervalSince1970,
                    "single",
                    state.winnerID,
                    state.turn,
                ]
            )
        }
    }

    // MARK: - ELO Records

    func saveELORecords(_ records: [ELORecord]) {
        guard let dbQueue else { return }
        try? dbQueue.write { db in
            for record in records {
                try db.execute(
                    sql: """
                    INSERT OR REPLACE INTO elo_records (id, playerId, model, elo, delta, gameId, rank, date)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    arguments: [
                        record.id, record.playerID, record.model,
                        record.elo, record.delta, record.gameID, record.rank,
                        record.date.timeIntervalSince1970,
                    ]
                )
            }
        }
    }

    func fetchELOHistory(for playerID: String, limit: Int = 20) -> [ELORecord] {
        guard let dbQueue else { return [] }
        return (try? dbQueue.read { db in
            let rows = try Row.fetchAll(db,
                sql: "SELECT * FROM elo_records WHERE playerId = ? ORDER BY date DESC LIMIT ?",
                arguments: [playerID, limit])
            return rows.map { row in
                ELORecord(
                    id: row["id"] as String? ?? UUID().uuidString,
                    playerID: row["playerId"] as String? ?? "",
                    model: row["model"] as String? ?? "",
                    elo: row["elo"] as Double? ?? 1500,
                    delta: row["delta"] as Double? ?? 0,
                    gameID: row["gameId"] as String? ?? "",
                    rank: row["rank"] as Int? ?? 1,
                    date: Date(timeIntervalSince1970: row["date"] as Double? ?? 0)
                )
            }
        }) ?? []
    }

    // MARK: - Settings

    func saveSetting(key: String, value: String) {
        guard let dbQueue else { return }
        try? dbQueue.write { db in
            try db.execute(
                sql: "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)",
                arguments: [key, value]
            )
        }
    }

    func loadSetting(key: String) -> String? {
        guard let dbQueue else { return nil }
        return try? dbQueue.read { db in
            try String.fetchOne(db, sql: "SELECT value FROM settings WHERE key = ?", arguments: [key])
        }
    }

    func saveSettings(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings),
              let json = String(data: data, encoding: .utf8) else { return }
        saveSetting(key: "app_settings", value: json)
    }

    func loadSettings() -> AppSettings {
        guard let json = loadSetting(key: "app_settings"),
              let data = json.data(using: .utf8),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    // MARK: - Events

    func saveEvents(_ events: [GameEvent]) {
        guard let dbQueue else { return }
        try? dbQueue.write { db in
            for event in events {
                try db.execute(
                    sql: """
                    INSERT OR REPLACE INTO game_events (id, gameId, turn, type, playerId, playerName, amount, description, timestamp)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    arguments: [
                        event.id, event.gameID, event.turn, event.type.rawValue,
                        event.playerID, event.playerName, event.amount, event.description,
                        event.timestamp.timeIntervalSince1970,
                    ]
                )
            }
        }
    }
}
