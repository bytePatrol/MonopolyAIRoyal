import Foundation
import Observation

// MARK: - Cost Entry

struct CostEntry: Identifiable, Codable {
    var id: String = UUID().uuidString
    var gameID: String
    var model: String
    var tokens: Int
    var costUSD: Double
    var date: Date = Date()
}

// MARK: - CostTracker

@Observable
@MainActor
final class CostTracker {
    var totalCost: Double = 0.0
    var todayCost: Double = 0.0
    var monthCost: Double = 0.0
    var currentGameCost: Double = 0.0
    var entries: [CostEntry] = []

    var settings: AppSettings = .default

    var isAtDailyLimit:   Bool { todayCost >= settings.maxCostPerDay }
    var isAtMonthlyLimit: Bool { monthCost >= settings.maxCostPerMonth }
    var isAtGameLimit:    Bool { currentGameCost >= settings.maxCostPerGame }

    // Cost per model (approximate USD per 1M tokens)
    private static let modelCosts: [String: (input: Double, output: Double)] = [
        "anthropic/claude-3-5-sonnet":         (3.0, 15.0),
        "openai/gpt-4-turbo":                  (10.0, 30.0),
        "google/gemini-pro-1.5":               (3.5, 10.5),
        "deepseek/deepseek-chat":              (0.14, 0.28),
        "meta-llama/llama-3-70b-instruct":     (0.59, 0.79),
        "mistralai/mistral-large":             (4.0, 12.0),
    ]

    // MARK: - Record

    func record(gameID: String, model: String, inputTokens: Int, outputTokens: Int) {
        let rates = Self.modelCosts[model] ?? (5.0, 15.0)
        let cost = (Double(inputTokens) / 1_000_000) * rates.input
                 + (Double(outputTokens) / 1_000_000) * rates.output

        let entry = CostEntry(gameID: gameID, model: model, tokens: inputTokens + outputTokens, costUSD: cost)
        entries.append(entry)
        totalCost += cost
        currentGameCost += cost

        let calendar = Calendar.current
        let now = Date()
        if calendar.isDateInToday(entry.date) { todayCost += cost }
        if calendar.isDate(entry.date, equalTo: now, toGranularity: .month) { monthCost += cost }
    }

    func resetGameCost() {
        currentGameCost = 0
    }

    func estimateCost(model: String, estimatedTokens: Int) -> Double {
        let rates = Self.modelCosts[model] ?? (5.0, 15.0)
        let avgRate = (rates.input + rates.output) / 2
        return (Double(estimatedTokens) / 1_000_000) * avgRate
    }

    // MARK: - Limit Check

    func canMakeDecision(model: String) -> Bool {
        guard settings.mockMode == false else { return true }
        return !isAtDailyLimit && !isAtMonthlyLimit && !isAtGameLimit
    }

    // MARK: - Formatted Display

    var formattedTotal: String { String(format: "$%.4f", totalCost) }
    var formattedToday: String { String(format: "$%.4f", todayCost) }
    var formattedMonth: String { String(format: "$%.2f", monthCost) }
    var formattedGame:  String { String(format: "$%.4f", currentGameCost) }

    var dailyPercent:   Double { min(todayCost / max(settings.maxCostPerDay, 0.01), 1.0) }
    var monthlyPercent: Double { min(monthCost / max(settings.maxCostPerMonth, 0.01), 1.0) }
    var gamePercent:    Double { min(currentGameCost / max(settings.maxCostPerGame, 0.01), 1.0) }
}
