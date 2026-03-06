import Foundation
import Observation

// MARK: - Chart Data Point

struct NetWorthPoint: Identifiable {
    var id: String { "\(playerID)-\(turn)" }
    var turn: Int
    var playerID: String
    var netWorth: Double
}

// MARK: - GameViewModel

@Observable
@MainActor
final class GameViewModel: GameEngineDelegate {
    // Game state (mirrored from engine)
    var gameState: GameState = GameState.mockState()
    var isGameRunning: Bool = false
    var isPaused: Bool = false
    var gameSpeed: GameEngine.GameSpeed = .normal

    // AI Brain panel
    var activePlayerReasoning: String = ""
    var activePlayerID: String = ""
    var reasoningConfidence: Double = 0.0

    // Win probabilities (updated each turn)
    var winProbabilities: [String: Double] = [:]

    // Commentary feed
    var commentary: [CommentaryEntry] = []

    // Net worth history for charts
    var netWorthHistory: [NetWorthPoint] = []

    // Cost tracking
    var costTracker: CostTracker = CostTracker()

    // Monte Carlo engine
    private let monteCarloEngine = MonteCarloEngine(simulationCount: 5_000)

    // Game Engine
    private var engine: GameEngine?

    // Narrator
    private let narrator = NarratorService.shared

    // MARK: - Init

    init() {
        loadMockCommentary()
        loadMockWinProbabilities()
    }

    // MARK: - Game Control

    func startNewGame(players: [AIPlayer]) {
        let settings = DatabaseService.shared.loadSettings()

        // Sync narrator settings before starting
        narrator.provider = settings.narratorProvider
        narrator.speed = Float(settings.narratorSpeed)
        narrator.isEnabled = settings.narratorEnabled
        narrator.chatterboxServerURL = settings.chatterboxServerURL
        narrator.selectedChatterboxVoice = settings.selectedChatterboxVoice

        // Sync commentary AI settings
        let commentaryAI = CommentaryEngine.shared
        commentaryAI.isAIEnabled = settings.commentaryAIEnabled
        commentaryAI.model = settings.commentaryModel
        commentaryAI.rateMultiplier = settings.commentaryRate / 0.65 // Normalize around default
        commentaryAI.reset()

        let eng = GameEngine(players: players, settings: settings)
        eng.delegate = self
        engine = eng
        gameState = eng.state
        activePlayerID = players.first?.id ?? ""
        activePlayerReasoning = ""
        netWorthHistory = []
        commentary = []
        costTracker.resetGameCost()
        winProbabilities = Dictionary(uniqueKeysWithValues: players.map { ($0.id, 1.0 / Double(players.count)) })
        eng.startGame()
        isGameRunning = true
    }

    func togglePause() {
        isPaused ? engine?.resume() : engine?.pause()
        isPaused.toggle()
    }

    func stopGame() {
        // Determine winner by highest net worth before stopping
        if gameState.winnerID == nil {
            let active = gameState.activePlayers
            gameState.winnerID = active.max(by: {
                gameState.calculateNetWorth(for: $0.id) < gameState.calculateNetWorth(for: $1.id)
            })?.id
        }
        gameState.phase = .gameOver
        gameState.endDate = Date()

        engine?.stopGame()
        isGameRunning = false
    }

    func setSpeed(_ speed: GameEngine.GameSpeed) {
        gameSpeed = speed
        engine?.speed = speed
    }

    // MARK: - GameEngineDelegate

    nonisolated func gameEngine(_ engine: GameEngine, didUpdateState state: GameState) {
        Task { @MainActor in
            self.gameState = state
            self.isGameRunning = engine.isRunning
            self.activePlayerID = state.currentPlayer?.id ?? ""
            self.recordNetWorth(state: state)
            await self.updateWinProbabilities(state: state)
        }
    }

    nonisolated func gameEngine(_ engine: GameEngine, didProduceReasoning reasoning: AIReasoning, for playerID: String) {
        Task { @MainActor in
            self.activePlayerReasoning = reasoning.reasoning
            self.reasoningConfidence = reasoning.confidence
        }
    }

    nonisolated func gameEngine(_ engine: GameEngine, didEndGame state: GameState) {
        Task { @MainActor in
            self.gameState = state
            self.isGameRunning = false
            self.addCommentary(text: "GAME OVER! \(state.winnerID?.uppercased() ?? "Unknown") wins!", type: .bankrupt)
        }
    }

    nonisolated func gameEngine(_ engine: GameEngine, didNeedNarration text: String, type: GameEventType) {
        Task { @MainActor in
            self.addCommentary(text: text, type: type)
        }
    }

    // MARK: - Win Probabilities

    private func updateWinProbabilities(state: GameState) async {
        guard state.turn % 5 == 0 else { return } // Update every 5 turns
        let probs = await monteCarloEngine.estimateWinProbabilities(from: state)
        self.winProbabilities = probs
    }

    // MARK: - Net Worth History

    private func recordNetWorth(state: GameState) {
        for player in state.players {
            let nw = Double(state.calculateNetWorth(for: player.id))
            netWorthHistory.append(NetWorthPoint(turn: state.turn, playerID: player.id, netWorth: nw))
        }
    }

    // MARK: - Commentary

    struct CommentaryEntry: Identifiable {
        var id = UUID()
        var text: String
        var type: GameEventType
        var timestamp: Date = Date()
        var timeString: String {
            let fmt = DateFormatter()
            fmt.dateFormat = "HH:mm:ss"
            return fmt.string(from: timestamp)
        }
    }

    func addCommentary(text: String, type: GameEventType) {
        let entry = CommentaryEntry(text: text, type: type)
        commentary.insert(entry, at: 0)
        if commentary.count > 50 { commentary.removeLast() }
    }

    private func loadMockCommentary() {
        commentary = [
            CommentaryEntry(text: "CLAUDE just landed on Boardwalk! This could be a game-changer.", type: .buy),
            CommentaryEntry(text: "GEMINI attempting to negotiate a railroad trade with GPT-4...", type: .trade),
            CommentaryEntry(text: "LLAMA pays $850 in rent — ouch! That hurts the cash position.", type: .rent),
            CommentaryEntry(text: "Welcome to Monopoly AI Royal! Six AI models enter, one exits victorious.", type: .roll),
        ]
    }

    private func loadMockWinProbabilities() {
        let players = AIPlayer.mockPlayers
        let probs: [Double] = [0.34, 0.22, 0.18, 0.12, 0.08, 0.06]
        for (player, prob) in zip(players, probs) {
            winProbabilities[player.id] = prob
        }
    }

    // MARK: - Game Results (for PostGame)

    func buildGameResults() -> GameResults {
        GameResults(
            state: gameState,
            winProbHistory: [],
            netWorthHistory: netWorthHistory,
            totalCost: costTracker.currentGameCost
        )
    }
}

// MARK: - Game Results

struct GameResults {
    var state: GameState
    var winProbHistory: [WinProbabilityPoint]
    var netWorthHistory: [NetWorthPoint]
    var totalCost: Double
}
