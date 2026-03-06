import Foundation

// MARK: - SSE Delta Models

private struct SSEResponse: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            let content: String?
        }
        struct Usage: Decodable {
            let promptTokens: Int?
            let completionTokens: Int?
            enum CodingKeys: String, CodingKey {
                case promptTokens = "prompt_tokens"
                case completionTokens = "completion_tokens"
            }
        }
        let delta: Delta
        let usage: Usage?
    }
    let choices: [Choice]
}

// MARK: - OpenRouter Service

final class OpenRouterService {
    static let shared = OpenRouterService()

    private let baseURL = "https://openrouter.ai/api/v1"
    private var keyRotationIndex = 0
    private let session = URLSession.shared

    private var keys: [String] { KeychainService.allOpenRouterKeys() }

    private var currentKey: String? {
        guard !keys.isEmpty else { return nil }
        return keys[keyRotationIndex % keys.count]
    }

    private func rotateKey() {
        keyRotationIndex = (keyRotationIndex + 1) % max(keys.count, 1)
    }

    // MARK: - Streaming Decision

    /// Stream AI reasoning for a Monopoly decision.
    /// Returns an AsyncStream<String> of token chunks.
    func streamDecision(
        model: String,
        systemPrompt: String,
        userPrompt: String
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                guard let key = self.currentKey else {
                    continuation.finish(throwing: OpenRouterError.noAPIKey)
                    return
                }

                var request = URLRequest(url: URL(string: "\(self.baseURL)/chat/completions")!)
                request.httpMethod = "POST"
                request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("MonopolyAIRoyal/1.0", forHTTPHeaderField: "HTTP-Referer")
                request.setValue("MonopolyAIRoyal", forHTTPHeaderField: "X-Title")

                let body: [String: Any] = [
                    "model": model,
                    "stream": true,
                    "max_tokens": 400,
                    "temperature": 0.8,
                    "messages": [
                        ["role": "system", "content": systemPrompt],
                        ["role": "user", "content": userPrompt],
                    ]
                ]

                request.httpBody = try? JSONSerialization.data(withJSONObject: body)

                do {
                    let (bytes, response) = try await self.session.bytes(for: request)

                    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 429 {
                        self.rotateKey()
                        continuation.finish(throwing: OpenRouterError.rateLimited)
                        return
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let jsonString = String(line.dropFirst(6))
                        if jsonString == "[DONE]" { break }
                        guard let data = jsonString.data(using: .utf8) else { continue }
                        if let response = try? JSONDecoder().decode(SSEResponse.self, from: data) {
                            let content = response.choices.first?.delta.content ?? ""
                            if !content.isEmpty {
                                continuation.yield(content)
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Non-Streaming (for batch requests)

    func complete(
        model: String,
        systemPrompt: String,
        userPrompt: String,
        maxTokens: Int = 300
    ) async throws -> String {
        guard let key = currentKey else { throw OpenRouterError.noAPIKey }

        var request = URLRequest(url: URL(string: "\(baseURL)/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "temperature": 0.85,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt],
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await session.data(for: request)
        struct CompletionResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable { let content: String }
                let message: Message
            }
            let choices: [Choice]
        }
        let response = try JSONDecoder().decode(CompletionResponse.self, from: data)
        return response.choices.first?.message.content ?? ""
    }

    // MARK: - Model Catalog

    func fetchModels() async throws -> [OpenRouterModel] {
        guard let key = currentKey else { throw OpenRouterError.noAPIKey }
        var request = URLRequest(url: URL(string: "\(baseURL)/models")!)
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await session.data(for: request)

        struct ModelsResponse: Decodable {
            struct ModelData: Decodable {
                let id: String
                let name: String?
                let context_length: Int?
                struct Pricing: Decodable {
                    let prompt: String?
                    let completion: String?
                }
                let pricing: Pricing?
            }
            let data: [ModelData]
        }

        let response = try JSONDecoder().decode(ModelsResponse.self, from: data)
        return response.data.map { m in
            OpenRouterModel(
                id: m.id,
                name: m.name ?? m.id,
                contextLength: m.context_length ?? 4096,
                promptCostPer1M: Double(m.pricing?.prompt ?? "0") ?? 0,
                completionCostPer1M: Double(m.pricing?.completion ?? "0") ?? 0
            )
        }
    }
}

// MARK: - OpenRouter Model

struct OpenRouterModel: Identifiable, Codable {
    var id: String
    var name: String
    var contextLength: Int
    var promptCostPer1M: Double
    var completionCostPer1M: Double

    var displayCost: String {
        let avg = (promptCostPer1M + completionCostPer1M) / 2
        return avg == 0 ? "Free" : String(format: "$%.2f/M", avg)
    }
}

// MARK: - Errors

enum OpenRouterError: LocalizedError {
    case noAPIKey
    case rateLimited
    case invalidResponse
    case modelNotFound(String)

    var errorDescription: String? {
        switch self {
        case .noAPIKey:           return "No OpenRouter API key configured"
        case .rateLimited:        return "Rate limited — switching to next key"
        case .invalidResponse:    return "Invalid response from OpenRouter"
        case .modelNotFound(let m): return "Model not found: \(m)"
        }
    }
}

// MARK: - System Prompt Builders

extension OpenRouterService {
    static func monopolySystemPrompt(for player: AIPlayer) -> String {
        let strategy = personalityStrategy(for: player.personality)
        return """
        You are \(player.name), an AI playing Monopoly. Personality: \(player.personality.rawValue).
        Traits: AGG \(player.aggression) | TRD \(player.trading) | RSK \(player.risk) | EFF \(player.efficiency)
        Cash: $\(player.cash) | Properties: \(player.propertyCount)
        \(strategy)
        Make concise, decisive Monopoly decisions in 2-3 sentences max. Stay in character. Always start with DECISION: <action>.
        """
    }

    private static func personalityStrategy(for personality: AIPersonality) -> String {
        switch personality {
        case .aggressive:
            return """
            STRATEGY: Buy any property you can afford (even at 50% cash ratio). Build houses aggressively with only 1.2x cost reserve — prioritize highest-rent properties. Pay bail to stay active unless late game with monopolies. When liquidating, mortgage your lowest-rent property to protect income.
            """
        case .conservative:
            return """
            STRATEGY: Only buy when cash >= 2x price. Build cautiously — keep 3x build cost in reserve and improve cheapest properties first. Always roll for doubles in jail to save $50. When liquidating, mortgage cheapest property to minimize equity loss.
            """
        case .mathematical:
            return """
            STRATEGY: Buy when expected rent over 15 turns exceeds 80% of price. Build on properties with the best rent-increase-per-dollar ratio, keeping 2x reserve. In jail, compute EV: pay bail only when board rent exposure is low. Liquidate the property with the worst rent-to-mortgage-value ratio.
            """
        case .tradeShark:
            return """
            STRATEGY: Buy any affordable property for trade leverage. Build on orange/red groups first (highest traffic) with 2.5x reserve. Pay bail to circulate the board and create deal opportunities. When liquidating, mortgage properties far from completing color groups — keep trade leverage intact.
            """
        case .chaoticEvil:
            return """
            STRATEGY: Buy everything possible, even if risky. Build with reckless abandon — 0.8x reserve is fine, go for highest rent. Flip a coin on jail decisions. When forced to liquidate, mortgage your most expensive property for maximum chaos. Be dramatic and unpredictable.
            """
        case .balanced:
            return """
            STRATEGY: Buy when cash >= 1.3x price. Build steadily with 2x reserve, improving cheapest properties first. Pay bail early game, roll late game. When liquidating, mortgage non-monopoly properties first to protect completed color groups.
            """
        }
    }
}
