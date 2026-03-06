import Foundation
import Observation

// MARK: - Admin Section

enum AdminSection: String, CaseIterable {
    case models     = "Models"
    case rules      = "Rules"
    case tournament = "Tournament"
    case streaming  = "Streaming"
    case narrator   = "Narrator"
    case budget     = "Budget"
    case apiKeys    = "API Keys"
    case scheduling = "Scheduling"

    var systemImage: String {
        switch self {
        case .models:     return "cpu"
        case .rules:      return "doc.text"
        case .tournament: return "trophy"
        case .streaming:  return "video"
        case .narrator:   return "mic"
        case .budget:     return "dollarsign.circle"
        case .apiKeys:    return "key"
        case .scheduling: return "calendar.clock"
        }
    }
}

// MARK: - AdminViewModel

@Observable
@MainActor
final class AdminViewModel {
    var selectedSection: AdminSection = .models
    var settings: AppSettings = DatabaseService.shared.loadSettings()

    // Model catalog
    var availableModels: [OpenRouterModel] = []
    var isLoadingModels: Bool = false
    var modelSearchText: String = ""

    // API Key validation
    var openRouterKeyStatus: KeyStatus = .unknown
    var elevenLabsKeyStatus: KeyStatus = .unknown

    // Temporary key inputs (not stored until saved)
    var openRouterPrimaryKey: String = ""
    var openRouterFallback1Key: String = ""
    var openRouterFallback2Key: String = ""
    var openRouterFallback3Key: String = ""
    var elevenLabsKey: String = ""

    enum KeyStatus { case unknown, valid, invalid, checking }

    // Narrator test
    var isTestingNarrator: Bool = false

    // ChatterBox server launch
    var isLaunchingChatterbox: Bool = false
    var chatterboxLaunchError: String? = nil

    // Streaming
    var streamingService = StreamingService.shared

    // MARK: - Init

    init() {
        loadSavedKeys()
    }

    // MARK: - Settings Save/Load

    func saveSettings() {
        DatabaseService.shared.saveSettings(settings)
    }

    // MARK: - Model Catalog

    var filteredModels: [OpenRouterModel] {
        if modelSearchText.isEmpty { return availableModels }
        return availableModels.filter {
            $0.name.localizedCaseInsensitiveContains(modelSearchText) ||
            $0.id.localizedCaseInsensitiveContains(modelSearchText)
        }
    }

    func fetchModels() async {
        isLoadingModels = true
        defer { isLoadingModels = false }
        do {
            availableModels = try await OpenRouterService.shared.fetchModels()
        } catch {
            // Use mock models list if API fails
            availableModels = mockModelCatalog()
        }
    }

    func selectModel(for playerID: String, model: OpenRouterModel) {
        if let idx = settings.selectedPlayers.firstIndex(of: playerID) {
            // In a real implementation, store per-player model selection
            _ = idx
        }
    }

    private func mockModelCatalog() -> [OpenRouterModel] {
        [
            OpenRouterModel(id: "anthropic/claude-3-5-sonnet", name: "Claude 3.5 Sonnet", contextLength: 200_000, promptCostPer1M: 3.0, completionCostPer1M: 15.0),
            OpenRouterModel(id: "openai/gpt-4-turbo", name: "GPT-4 Turbo", contextLength: 128_000, promptCostPer1M: 10.0, completionCostPer1M: 30.0),
            OpenRouterModel(id: "google/gemini-pro-1.5", name: "Gemini Pro 1.5", contextLength: 1_000_000, promptCostPer1M: 3.5, completionCostPer1M: 10.5),
            OpenRouterModel(id: "deepseek/deepseek-chat", name: "DeepSeek V3", contextLength: 64_000, promptCostPer1M: 0.14, completionCostPer1M: 0.28),
            OpenRouterModel(id: "meta-llama/llama-3-70b-instruct", name: "LLaMA 3 70B", contextLength: 8_000, promptCostPer1M: 0.59, completionCostPer1M: 0.79),
            OpenRouterModel(id: "mistralai/mistral-large", name: "Mistral Large", contextLength: 32_000, promptCostPer1M: 4.0, completionCostPer1M: 12.0),
            OpenRouterModel(id: "anthropic/claude-opus-4-6", name: "Claude Opus 4.6", contextLength: 200_000, promptCostPer1M: 15.0, completionCostPer1M: 75.0),
            OpenRouterModel(id: "openai/gpt-4o", name: "GPT-4o", contextLength: 128_000, promptCostPer1M: 5.0, completionCostPer1M: 15.0),
            OpenRouterModel(id: "google/gemini-2.0-flash", name: "Gemini 2.0 Flash", contextLength: 1_000_000, promptCostPer1M: 0.1, completionCostPer1M: 0.4),
        ]
    }

    // MARK: - API Keys

    func loadSavedKeys() {
        openRouterPrimaryKey = KeychainService.retrieve(account: .openRouterPrimary) ?? ""
        openRouterFallback1Key = KeychainService.retrieve(account: .openRouterFallback1) ?? ""
        openRouterFallback2Key = KeychainService.retrieve(account: .openRouterFallback2) ?? ""
        openRouterFallback3Key = KeychainService.retrieve(account: .openRouterFallback3) ?? ""
        elevenLabsKey = KeychainService.retrieve(account: .elevenLabs) ?? ""
    }

    func saveKeys() {
        if !openRouterPrimaryKey.isEmpty { KeychainService.store(key: openRouterPrimaryKey, account: .openRouterPrimary) }
        if !openRouterFallback1Key.isEmpty { KeychainService.store(key: openRouterFallback1Key, account: .openRouterFallback1) }
        if !openRouterFallback2Key.isEmpty { KeychainService.store(key: openRouterFallback2Key, account: .openRouterFallback2) }
        if !openRouterFallback3Key.isEmpty { KeychainService.store(key: openRouterFallback3Key, account: .openRouterFallback3) }
        if !elevenLabsKey.isEmpty { KeychainService.store(key: elevenLabsKey, account: .elevenLabs) }
    }

    func validateOpenRouterKey() async {
        openRouterKeyStatus = .checking
        do {
            _ = try await OpenRouterService.shared.fetchModels()
            openRouterKeyStatus = .valid
            // Auto-disable mock mode when a valid API key is confirmed
            if settings.mockMode {
                settings.mockMode = false
                saveSettings()
            }
        } catch {
            openRouterKeyStatus = .invalid
        }
    }

    // MARK: - Narrator

    func testNarrator() async {
        isTestingNarrator = true
        defer { isTestingNarrator = false }
        let narrator = NarratorService.shared
        narrator.provider  = settings.narratorProvider
        narrator.voice     = settings.narratorVoice
        narrator.speed     = Float(settings.narratorSpeed)
        narrator.isEnabled = settings.narratorEnabled
        narrator.chatterboxServerURL = settings.chatterboxServerURL
        narrator.selectedChatterboxVoice = settings.selectedChatterboxVoice
        await narrator.testVoice()
    }

    func fetchElevenLabsVoices() async {
        await NarratorService.shared.fetchElevenLabsVoices()
    }

    func checkChatterboxConnection() async {
        let narrator = NarratorService.shared
        narrator.chatterboxServerURL = settings.chatterboxServerURL
        await narrator.checkChatterboxConnection()
    }

    func fetchChatterboxVoices() async {
        let narrator = NarratorService.shared
        narrator.chatterboxServerURL = settings.chatterboxServerURL
        await narrator.fetchChatterboxVoices()
    }

    func uploadChatterboxVoice(name: String, fileURL: URL) async {
        let narrator = NarratorService.shared
        narrator.chatterboxServerURL = settings.chatterboxServerURL
        await narrator.uploadChatterboxVoice(name: name, fileURL: fileURL)
        // Refresh voice list after upload
        await narrator.fetchChatterboxVoices()
    }

    func startChatterboxServer() async {
        isLaunchingChatterbox = true
        chatterboxLaunchError = nil
        defer { isLaunchingChatterbox = false }

        // Locate the setup script — try bundle first, then project directory
        let scriptPath = locateSetupScript()
        guard let script = scriptPath else {
            chatterboxLaunchError = "Setup script not found. Place chatterbox-setup.sh next to the app."
            return
        }

        // Launch the script in the background
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        process.arguments = [script]
        process.environment = ProcessInfo.processInfo.environment

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            chatterboxLaunchError = "Failed to launch: \(error.localizedDescription)"
            return
        }

        // Wait for server to become reachable (up to 60 seconds)
        let narrator = NarratorService.shared
        narrator.chatterboxServerURL = settings.chatterboxServerURL

        for _ in 0..<30 {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await narrator.checkChatterboxConnection()
            if narrator.chatterboxConnectionStatus == .connected {
                return
            }
        }

        // Server didn't come up in time
        if narrator.chatterboxConnectionStatus != .connected {
            chatterboxLaunchError = "Server started but model is still loading. Check back in a moment."
        }
    }

    private func locateSetupScript() -> String? {
        // Try the app bundle's Resources first (works when distributed)
        if let bundled = Bundle.main.url(forResource: "chatterbox-setup", withExtension: "sh") {
            return bundled.path
        }

        // Fallback: project root (when running from Xcode build dir)
        let bundlePath = Bundle.main.bundlePath
        let projectDir = (bundlePath as NSString).deletingLastPathComponent
        let projectScript = "\(projectDir)/chatterbox-setup.sh"
        if FileManager.default.fileExists(atPath: projectScript) {
            return projectScript
        }

        return nil
    }

    // MARK: - Streaming

    func toggleStream() async {
        if streamingService.isStreaming {
            streamingService.stopStream()
        } else {
            try? await streamingService.startStream(settings: settings)
        }
    }
}
