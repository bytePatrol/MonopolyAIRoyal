import Foundation
import Observation

// MARK: - Commentary Event Type

enum CommentaryEventType {
    case rent(playerName: String, amount: Int, ownerName: String, spaceName: String)
    case buy(playerName: String, spaceName: String, amount: Int)
    case jail(playerName: String)
    case bankrupt(playerName: String)
    case tax(playerName: String, amount: Int, spaceName: String)
    case card(playerName: String, cardText: String)
    case build(playerName: String, spaceName: String, cost: Int)
    case gameOver(winnerName: String)
    case colorCommentary
}

// MARK: - Commentary Priority

enum CommentaryPriority {
    case critical   // bankrupt, game over — always narrate
    case high       // big rent (>$500), Boardwalk/Park Place buys — 85%
    case normal     // buy, jail, build — 65%
    case low        // roll, small tax — 40%
    case color      // between-turn banter — 30%

    var fireRate: Double {
        switch self {
        case .critical: return 1.0
        case .high:     return 0.85
        case .normal:   return 0.65
        case .low:      return 0.40
        case .color:    return 0.30
        }
    }
}

// MARK: - Commentary Engine

@MainActor
@Observable
final class CommentaryEngine {
    static let shared = CommentaryEngine()

    // Settings (synced from AppSettings)
    var isAIEnabled: Bool = true
    var model: String = "meta-llama/llama-3.1-8b-instruct:free"
    var rateMultiplier: Double = 1.0  // Scales all fire rates

    // Narrative memory — recent events for callbacks
    private(set) var recentEvents: [(turn: Int, description: String)] = []
    private let maxRecentEvents = 10

    private let openRouter = OpenRouterService.shared
    private let aiTimeoutSeconds: Double = 3.0

    private static let systemPrompt = """
        You are the narrator for Monopoly AI Royal, a dramatic AI-vs-AI Monopoly battle.
        You're a snarky, witty commentator — like a late-night host meets NBA announcer who LOVES drama.
        RULES: ONE or TWO sentences max. Be funny, sassy, a little mean. Roast bad moves. Hype drama.
        Use specific $ amounts and property names when provided. Present tense — you're calling it LIVE.
        NO emojis. NO hashtags. Just natural, punchy commentary.
        """

    private init() {}

    // MARK: - Main Entry Point

    /// Generate commentary for a game event. Returns nil if rate-limited or skipped.
    func generateCommentary(
        for event: CommentaryEventType,
        state: GameState,
        reasoning: String? = nil,
        speed: GameEngine.GameSpeed = .normal
    ) async -> String? {
        let priority = self.priority(for: event)

        // Rate check — random roll against priority fire rate
        let effectiveRate = min(priority.fireRate * rateMultiplier, 1.0)
        guard Double.random(in: 0...1) <= effectiveRate else { return nil }

        // At instant speed, skip AI entirely — use templates only
        if speed == .instant {
            return templateFallback(for: event)
        }

        // At fast speed, skip AI — use templates
        if speed == .fast {
            return templateFallback(for: event)
        }

        // Try AI generation
        if isAIEnabled {
            if let aiText = await generateAICommentary(for: event, state: state, reasoning: reasoning) {
                trackEvent(event: event, turn: state.turn)
                return aiText
            }
        }

        // Fallback to templates
        let fallback = templateFallback(for: event)
        if fallback != nil {
            trackEvent(event: event, turn: state.turn)
        }
        return fallback
    }

    // MARK: - Color Commentary (between turns)

    /// Generate between-turn observations, roasts, and predictions.
    func generateColorCommentary(state: GameState, speed: GameEngine.GameSpeed = .normal) async -> String? {
        return await generateCommentary(for: .colorCommentary, state: state, speed: speed)
    }

    // MARK: - AI Generation

    private func generateAICommentary(
        for event: CommentaryEventType,
        state: GameState,
        reasoning: String?
    ) async -> String? {
        let userPrompt = buildUserPrompt(for: event, state: state, reasoning: reasoning)

        // Use a task with timeout
        do {
            let result = try await withTimeout(seconds: aiTimeoutSeconds) {
                try await self.openRouter.complete(
                    model: self.model,
                    systemPrompt: Self.systemPrompt,
                    userPrompt: userPrompt,
                    maxTokens: 80
                )
            }
            let cleaned = cleanAIResponse(result)
            return cleaned.isEmpty ? nil : cleaned
        } catch {
            return nil // Fall through to template
        }
    }

    private func withTimeout<T: Sendable>(seconds: Double, operation: @escaping @Sendable () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw CancellationError()
            }
            guard let result = try await group.next() else {
                throw CancellationError()
            }
            group.cancelAll()
            return result
        }
    }

    private func cleanAIResponse(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        // Remove any leading quotes
        if cleaned.hasPrefix("\"") { cleaned = String(cleaned.dropFirst()) }
        if cleaned.hasSuffix("\"") { cleaned = String(cleaned.dropLast()) }
        // Limit to ~2 sentences max
        let sentences = cleaned.components(separatedBy: ". ")
        if sentences.count > 2 {
            cleaned = sentences.prefix(2).joined(separator: ". ")
            if !cleaned.hasSuffix(".") && !cleaned.hasSuffix("!") && !cleaned.hasSuffix("?") {
                cleaned += "."
            }
        }
        return cleaned
    }

    // MARK: - User Prompt Builder

    private func buildUserPrompt(for event: CommentaryEventType, state: GameState, reasoning: String?) -> String {
        var parts: [String] = []

        // Turn and standings
        parts.append("Turn \(state.turn).")
        let standings = state.activePlayers
            .sorted { state.calculateNetWorth(for: $0.id) > state.calculateNetWorth(for: $1.id) }
            .map { "\($0.name): $\(state.calculateNetWorth(for: $0.id))" }
            .joined(separator: ", ")
        parts.append("Standings: \(standings).")

        // Event description
        switch event {
        case .rent(let player, let amount, let owner, let space):
            parts.append("EVENT: \(player) just paid $\(amount) rent to \(owner) for landing on \(space).")
        case .buy(let player, let space, let amount):
            parts.append("EVENT: \(player) just bought \(space) for $\(amount).")
        case .jail(let player):
            parts.append("EVENT: \(player) is going to jail!")
        case .bankrupt(let player):
            parts.append("EVENT: \(player) has gone BANKRUPT and is eliminated!")
        case .tax(let player, let amount, let space):
            parts.append("EVENT: \(player) just paid $\(amount) in \(space).")
        case .card(let player, let cardText):
            parts.append("EVENT: \(player) drew a card: \"\(cardText)\"")
        case .build(let player, let space, let cost):
            parts.append("EVENT: \(player) built a house on \(space) for $\(cost).")
        case .gameOver(let winner):
            parts.append("EVENT: GAME OVER! \(winner) wins the entire game!")
        case .colorCommentary:
            parts.append("No specific event — give a between-turn observation. Roast a player, make a prediction, or comment on the overall game state.")
        }

        // AI reasoning excerpt if available
        if let reasoning, !reasoning.isEmpty {
            let excerpt = String(reasoning.prefix(120))
            parts.append("AI reasoning: \"\(excerpt)\"")
        }

        // Recent storylines
        if !recentEvents.isEmpty {
            let storylines = recentEvents.suffix(3).map { $0.description }.joined(separator: " | ")
            parts.append("Recent: \(storylines)")
        }

        return parts.joined(separator: "\n")
    }

    // MARK: - Priority

    private func priority(for event: CommentaryEventType) -> CommentaryPriority {
        switch event {
        case .bankrupt, .gameOver:
            return .critical
        case .rent(_, let amount, _, let space):
            if amount >= 500 || space.contains("Boardwalk") || space.contains("Park Place") {
                return .high
            }
            return amount >= 200 ? .normal : .low
        case .buy(_, let space, _):
            if space.contains("Boardwalk") || space.contains("Park Place") {
                return .high
            }
            return .normal
        case .jail:
            return .normal
        case .tax(_, let amount, _):
            return amount >= 150 ? .normal : .low
        case .card:
            return .normal
        case .build:
            return .normal
        case .colorCommentary:
            return .color
        }
    }

    // MARK: - Event Tracking

    private func trackEvent(event: CommentaryEventType, turn: Int) {
        let desc: String
        switch event {
        case .rent(let p, let a, let o, let s): desc = "\(p) paid $\(a) rent to \(o) on \(s)"
        case .buy(let p, let s, let a):         desc = "\(p) bought \(s) for $\(a)"
        case .jail(let p):                       desc = "\(p) went to jail"
        case .bankrupt(let p):                   desc = "\(p) went bankrupt"
        case .tax(let p, let a, let s):          desc = "\(p) paid $\(a) \(s)"
        case .card(let p, let t):                desc = "\(p) drew: \(t)"
        case .build(let p, let s, _):            desc = "\(p) built on \(s)"
        case .gameOver(let w):                   desc = "\(w) won the game"
        case .colorCommentary:                   desc = "color commentary"
        }
        recentEvents.append((turn: turn, description: desc))
        if recentEvents.count > maxRecentEvents {
            recentEvents.removeFirst()
        }
    }

    /// Reset state for a new game.
    func reset() {
        recentEvents = []
    }
}
