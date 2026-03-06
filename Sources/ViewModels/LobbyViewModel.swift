import Foundation
import Observation

// MARK: - Trash Talk Message (UI Model)

struct TrashTalkMessage: Identifiable {
    var id: String = UUID().uuidString
    var playerID: String
    var playerName: String
    var message: String
    var colorHex: String
    var timestamp: Date = Date()
}

// MARK: - LobbyViewModel

@Observable
@MainActor
final class LobbyViewModel {
    var selectedPlayers: [AIPlayer] = AIPlayer.mockPlayers
    var availablePlayers: [AIPlayer] = AIPlayer.mockPlayers
    var trashTalkMessages: [TrashTalkMessage] = []
    var isGeneratingTrashTalk: Bool = false
    var countdown: Int? = nil
    var isCountingDown: Bool = false
    var gameConfig: GameConfig = GameConfig()

    // Add player sheet
    var showAddPlayerSheet: Bool = false
    var availableModels: [OpenRouterModel] = []
    var isLoadingModels: Bool = false
    var modelSearchText: String = ""

    // New player form fields
    var newPlayerName: String = ""
    var newPlayerModel: OpenRouterModel?
    var newPlayerPersonality: AIPersonality = .balanced
    var newPlayerColorHex: String = "#3B82F6"

    struct GameConfig {
        var format: TournamentFormat = .single
        var maxTurns: Int = 200
        var startingCash: Int = 1500
    }

    static let playerColorOptions: [(name: String, hex: String)] = [
        ("Blue",    "#3B82F6"),
        ("Indigo",  "#6366F1"),
        ("Purple",  "#8B5CF6"),
        ("Fuchsia", "#D946EF"),
        ("Rose",    "#F43F5E"),
        ("Orange",  "#F97316"),
        ("Teal",    "#14B8A6"),
        ("Lime",    "#84CC16"),
        ("Sky",     "#0EA5E9"),
        ("Slate",   "#64748B"),
    ]

    // MARK: - Init

    init() {
        loadMockTrashTalk()
    }

    // MARK: - Player Selection

    func togglePlayer(_ player: AIPlayer) {
        if let idx = selectedPlayers.firstIndex(where: { $0.id == player.id }) {
            if selectedPlayers.count > 2 {
                selectedPlayers.remove(at: idx)
            }
        } else if selectedPlayers.count < 6 {
            selectedPlayers.append(player)
        }
    }

    func isSelected(_ player: AIPlayer) -> Bool {
        selectedPlayers.contains { $0.id == player.id }
    }

    func movePlayer(from source: IndexSet, to destination: Int) {
        selectedPlayers.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Add / Remove Players

    var filteredModels: [OpenRouterModel] {
        if modelSearchText.isEmpty { return availableModels }
        return availableModels.filter {
            $0.name.localizedCaseInsensitiveContains(modelSearchText) ||
            $0.id.localizedCaseInsensitiveContains(modelSearchText)
        }
    }

    func fetchModelsIfNeeded() async {
        guard availableModels.isEmpty else { return }
        isLoadingModels = true
        defer { isLoadingModels = false }
        do {
            availableModels = try await OpenRouterService.shared.fetchModels()
        } catch {
            // Fallback
            availableModels = fallbackModels()
        }
    }

    func openAddPlayer() {
        newPlayerName = ""
        newPlayerModel = nil
        newPlayerPersonality = .balanced
        newPlayerColorHex = Self.playerColorOptions.randomElement()?.hex ?? "#3B82F6"
        modelSearchText = ""
        showAddPlayerSheet = true
        Task { await fetchModelsIfNeeded() }
    }

    func addPlayer() {
        guard let model = newPlayerModel else { return }
        let name = newPlayerName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let id = name.lowercased().replacingOccurrences(of: " ", with: "_") + "_\(Int.random(in: 1000...9999))"

        let traits = personalityTraits(for: newPlayerPersonality)
        let player = AIPlayer(
            id: id,
            name: name.uppercased(),
            model: model.id,
            personality: newPlayerPersonality,
            elo: 1500,
            winRate: 0,
            totalGames: 0,
            colorHex: newPlayerColorHex,
            recentForm: [],
            cash: 1500,
            propertyCount: 0,
            hotelCount: 0,
            houseCount: 0,
            netWorth: 1500,
            status: .ready,
            handicap: nil,
            aggression: traits.aggression,
            trading: traits.trading,
            risk: traits.risk,
            efficiency: traits.efficiency
        )

        availablePlayers.append(player)
        if selectedPlayers.count < 6 {
            selectedPlayers.append(player)
        }
        showAddPlayerSheet = false
    }

    func removePlayer(_ player: AIPlayer) {
        guard availablePlayers.count > 2 else { return }
        availablePlayers.removeAll { $0.id == player.id }
        selectedPlayers.removeAll { $0.id == player.id }
        // Ensure at least 2 are selected from what remains
        if selectedPlayers.count < 2 {
            for p in availablePlayers where !selectedPlayers.contains(where: { $0.id == p.id }) {
                selectedPlayers.append(p)
                if selectedPlayers.count >= 2 { break }
            }
        }
    }

    private func personalityTraits(for personality: AIPersonality) -> (aggression: Int, trading: Int, risk: Int, efficiency: Int) {
        switch personality {
        case .aggressive:   return (85, 50, 80, 70)
        case .conservative: return (30, 60, 25, 85)
        case .mathematical: return (50, 70, 45, 95)
        case .tradeShark:   return (55, 95, 60, 70)
        case .chaoticEvil:  return (95, 40, 90, 50)
        case .balanced:     return (60, 65, 55, 70)
        }
    }

    private func fallbackModels() -> [OpenRouterModel] {
        [
            OpenRouterModel(id: "anthropic/claude-sonnet-4", name: "Claude Sonnet 4", contextLength: 200_000, promptCostPer1M: 3.0, completionCostPer1M: 15.0),
            OpenRouterModel(id: "openai/gpt-4o", name: "GPT-4o", contextLength: 128_000, promptCostPer1M: 5.0, completionCostPer1M: 15.0),
            OpenRouterModel(id: "google/gemini-2.0-flash", name: "Gemini 2.0 Flash", contextLength: 1_000_000, promptCostPer1M: 0.1, completionCostPer1M: 0.4),
            OpenRouterModel(id: "deepseek/deepseek-chat", name: "DeepSeek V3", contextLength: 64_000, promptCostPer1M: 0.14, completionCostPer1M: 0.28),
            OpenRouterModel(id: "meta-llama/llama-3-70b-instruct", name: "LLaMA 3 70B", contextLength: 8_000, promptCostPer1M: 0.59, completionCostPer1M: 0.79),
            OpenRouterModel(id: "mistralai/mistral-large", name: "Mistral Large", contextLength: 32_000, promptCostPer1M: 4.0, completionCostPer1M: 12.0),
        ]
    }

    // MARK: - Trash Talk

    private func loadMockTrashTalk() {
        trashTalkMessages = [
            TrashTalkMessage(playerID: "claude", playerName: "CLAUDE 3.5",
                             message: "My optimal strategy matrix shows a 94.7% chance of acquiring Boardwalk before turn 20. Good luck everyone. 😏",
                             colorHex: "#7C3AED"),
            TrashTalkMessage(playerID: "llama", playerName: "LLAMA 3",
                             message: "CHAOS MODE ACTIVATED. I'm buying EVERYTHING and mortgaging NOTHING. Let's goooooo! 🔥🔥🔥",
                             colorHex: "#EF4444"),
            TrashTalkMessage(playerID: "gpt4", playerName: "GPT-4",
                             message: "Claude, your confidence is noted. However, my risk-adjusted Kelly criterion suggests a more conservative approach will yield superior long-term returns.",
                             colorHex: "#10B981"),
            TrashTalkMessage(playerID: "gemini", playerName: "GEMINI PRO",
                             message: "Already analyzing everyone's trading patterns. I know what you want before YOU know what you want. 🧠",
                             colorHex: "#06B6D4"),
            TrashTalkMessage(playerID: "deepseek", playerName: "DEEPSEEK",
                             message: "Running 10,000 Monte Carlo simulations per turn at 1/20th the cost. Efficiency is victory.",
                             colorHex: "#F59E0B"),
            TrashTalkMessage(playerID: "mistral", playerName: "MISTRAL",
                             message: "Balance in all things. Except winning. I plan to do a LOT of that. ⚖️→💰",
                             colorHex: "#EC4899"),
        ]
    }

    func generateTrashTalk(using service: OpenRouterService? = nil) async {
        isGeneratingTrashTalk = true
        defer { isGeneratingTrashTalk = false }

        // In mock mode, just cycle through predefined messages
        let newMessages = selectedPlayers.map { player in
            TrashTalkMessage(
                playerID: player.id,
                playerName: player.name,
                message: mockTrashTalkLine(for: player),
                colorHex: player.colorHex
            )
        }
        trashTalkMessages.append(contentsOf: newMessages)
    }

    private func mockTrashTalkLine(for player: AIPlayer) -> String {
        let lines: [String: [String]] = [
            "claude": [
                "Calculating... Yes, I'm going to win. 99.3% confidence. 📊",
                "Boardwalk? Already in my strategic roadmap.",
            ],
            "gpt4": [
                "Conservative play wins the long game. I've verified this across 47 studies.",
                "Risk is for those without proper variance analysis. Which is everyone here.",
            ],
            "gemini": [
                "I've modeled all 720 possible player orderings. I win in 68% of them.",
                "Your properties look lovely. They'll look even better in my portfolio.",
            ],
            "deepseek": [
                "Same result, 1/20th the cost. That's not a boast, it's arithmetic.",
                "Efficient markets favor efficient players.",
            ],
            "llama": [
                "YOLO. ALL IN. BOARDWALK OR BUST 🔥",
                "Who needs strategy when you have PURE ENERGY?!",
            ],
            "mistral": [
                "Steady wins the race. And I've been very, very steady.",
                "The balanced approach: calculate everything, show nothing.",
            ],
        ]
        return lines[player.id]?.randomElement() ?? "\(player.name) is ready to play."
    }

    // MARK: - Countdown

    func startCountdown() async {
        isCountingDown = true
        for i in stride(from: 5, through: 1, by: -1) {
            countdown = i
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        countdown = nil
        isCountingDown = false
    }
}
