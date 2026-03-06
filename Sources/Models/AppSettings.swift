import Foundation

// MARK: - App Settings

struct AppSettings: Codable {
    // General rules
    var startingCash: Int = 1500
    var goSalary: Int = 200
    var jailBail: Int = 50
    var maxTurns: Int = 200
    var freeParkingJackpot: Bool = false
    var auctionUnboughtProperties: Bool = true
    var noRentInJail: Bool = false
    var winCondition: WinCondition = .lastStanding
    var doublesGetOutOfJail: Bool = true
    var rollDoublesTwiceOnDoubles: Bool = true

    // AI settings
    var mockMode: Bool = true       // No API calls; scripted decisions
    var maxDecisionTimeSeconds: Int = 30
    var thinkingVerbosity: ThinkingVerbosity = .full
    var selectedPlayers: [String] = AIPlayer.mockPlayers.map { $0.id }

    // Budget / cost limits
    var maxCostPerDecision: Double = 0.05
    var maxCostPerGame: Double = 2.00
    var maxCostPerDay: Double = 10.00
    var maxCostPerMonth: Double = 50.00

    // Tournament
    var tournamentFormat: TournamentFormat = .single
    var seriesLength: Int = 3

    // Streaming
    var streamingEnabled: Bool = false
    var streamPlatform: StreamPlatform = .youtube
    var rtmpURL: String = ""
    var rtmpKey: String = ""
    var resolutionWidth: Int = 1920
    var resolutionHeight: Int = 1080
    var videoBitrate: Int = 6000
    var videoCodec: VideoCodec = .h264

    // Narrator
    var narratorEnabled: Bool = true
    var narratorVoice: NarratorVoice = .marcus
    var narratorProvider: NarratorProvider = .elevenLabs
    var narratorSpeed: Double = 1.0
    var narratorPitch: Double = 1.0
    var chatterboxServerURL: String = "http://127.0.0.1:4123"
    var selectedChatterboxVoice: String? = nil

    // Commentary AI
    var commentaryAIEnabled: Bool = true
    var commentaryModel: String = "meta-llama/llama-3.1-8b-instruct:free"
    var commentaryRate: Double = 0.65

    // Scheduling
    var autoStartEnabled: Bool = false
    var autoStartTime: Date = Date()
    var repeatSchedule: RepeatSchedule = .never
    var unattendedMode: Bool = false

    // Static default
    static let `default` = AppSettings()
}

enum WinCondition: String, Codable, CaseIterable {
    case lastStanding  = "Last Standing"
    case netWorth      = "Highest Net Worth at Turn Limit"
    case firstBillion  = "First to $5,000"
}

enum ThinkingVerbosity: String, Codable, CaseIterable {
    case minimal = "Minimal"
    case normal  = "Normal"
    case full    = "Full"
}

enum StreamPlatform: String, Codable, CaseIterable {
    case youtube = "YouTube"
    case twitch  = "Twitch"
    case kick    = "Kick"
    case custom  = "Custom RTMP"
}

enum VideoCodec: String, Codable, CaseIterable {
    case h264 = "H.264"
    case h265 = "H.265 (HEVC)"
}

enum NarratorVoice: String, Codable, CaseIterable {
    case marcus    = "Marcus"
    case aria      = "Aria"
    case nova      = "Nova"
    case echo      = "Echo"
    case alloy     = "Alloy"
}

enum NarratorProvider: String, Codable, CaseIterable {
    case elevenLabs = "ElevenLabs"
    case openAI     = "OpenAI TTS"
    case chatterbox = "ChatterBox"
}

enum RepeatSchedule: String, Codable, CaseIterable {
    case never  = "Never"
    case daily  = "Daily"
    case weekly = "Weekly"
}
