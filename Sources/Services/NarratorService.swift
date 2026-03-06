import Foundation
import AVFoundation

// MARK: - ElevenLabs Voice Model

struct ElevenLabsVoice: Identifiable, Codable, Hashable {
    let voice_id: String
    let name: String
    var id: String { voice_id }
}

private struct ElevenLabsVoicesResponse: Codable {
    let voices: [ElevenLabsVoice]
}

// MARK: - ChatterBox Voice Model

struct ChatterboxVoice: Identifiable, Codable, Hashable {
    let name: String
    let language: String?
    let file_size: Int?
    var id: String { name }
}

// MARK: - ChatterBox Connection Status

enum ChatterboxConnectionStatus: String {
    case unknown     = "Not checked"
    case connected   = "Connected"
    case unreachable = "Unreachable"
    case error       = "Error"
}

// MARK: - Narrator Service

@MainActor
@Observable
final class NarratorService {
    static let shared = NarratorService()

    var isEnabled: Bool = true
    var isSpeaking: Bool = false
    var voice: NarratorVoice = .marcus
    var provider: NarratorProvider = .elevenLabs
    var speed: Float = 1.0
    var volume: Float = 0.85

    // ElevenLabs voice list
    var availableVoices: [ElevenLabsVoice] = []
    var selectedElevenLabsVoiceID: String? = nil
    var isFetchingVoices: Bool = false
    var voiceFetchError: String? = nil

    // ChatterBox state
    var chatterboxServerURL: String = "http://127.0.0.1:4123"
    var chatterboxConnectionStatus: ChatterboxConnectionStatus = .unknown
    var isCheckingChatterbox: Bool = false
    var chatterboxVoices: [ChatterboxVoice] = []
    var selectedChatterboxVoice: String? = nil
    var isFetchingChatterboxVoices: Bool = false
    var chatterboxVoiceFetchError: String? = nil
    var isUploadingVoice: Bool = false
    var voiceUploadError: String? = nil

    private var synthesizer = AVSpeechSynthesizer()
    private var audioPlayer: AVAudioPlayer?
    private let session = URLSession.shared

    /// Tracks if Chatterbox has failed in this session — stops retrying until connection is re-tested.
    private var chatterboxFailed: Bool = false

    private init() {}

    // MARK: - Narrate

    func narrate(_ text: String) async {
        guard isEnabled else { return }
        isSpeaking = true
        defer { isSpeaking = false }

        let effectiveProvider: NarratorProvider
        if provider == .chatterbox && chatterboxFailed {
            effectiveProvider = .elevenLabs
        } else {
            effectiveProvider = provider
        }

        switch effectiveProvider {
        case .openAI:
            await narrateWithOpenAI(text)
        case .elevenLabs:
            await narrateWithElevenLabs(text)
        case .chatterbox:
            await narrateWithChatterbox(text)
        }
    }

    // MARK: - OpenAI TTS

    private func narrateWithOpenAI(_ text: String) async {
        // OpenAI TTS requires a separate OpenAI API key (not OpenRouter)
        await narrateWithSystem(text)
    }

    // MARK: - ElevenLabs TTS

    private func narrateWithElevenLabs(_ text: String) async {
        guard let key = KeychainService.retrieve(account: .elevenLabs) else {
            await narrateWithSystem(text)
            return
        }

        let voiceID = selectedElevenLabsVoiceID ?? elevenLabsDefaultVoiceID()
        // Use non-streaming endpoint so we get a complete MP3 blob AVAudioPlayer can handle
        let urlString = "https://api.elevenlabs.io/v1/text-to-speech/\(voiceID)"
        guard let url = URL(string: urlString) else {
            await narrateWithSystem(text)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("audio/mpeg", forHTTPHeaderField: "Accept")

        let body: [String: Any] = [
            "text": text,
            "model_id": "eleven_multilingual_v2",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75,
                "speed": Double(speed)
            ]
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        guard let (data, response) = try? await session.data(for: request),
              (response as? HTTPURLResponse)?.statusCode == 200 else {
            await narrateWithSystem(text)
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(data: data, fileTypeHint: "mp3")
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            while audioPlayer?.isPlaying == true {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        } catch {
            await narrateWithSystem(text)
        }
    }

    // MARK: - Fetch ElevenLabs Voice List

    func fetchElevenLabsVoices() async {
        voiceFetchError = nil
        isFetchingVoices = true
        defer { isFetchingVoices = false }

        guard let key = KeychainService.retrieve(account: .elevenLabs), !key.isEmpty else {
            voiceFetchError = "No ElevenLabs API key found — save it in API Keys first."
            return
        }

        var components = URLComponents(string: "https://api.elevenlabs.io/v1/voices")!
        components.queryItems = [URLQueryItem(name: "show_legacy_voices", value: "false")]
        var request = URLRequest(url: components.url!)
        request.setValue(key, forHTTPHeaderField: "xi-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let httpStatus: Int
        do {
            let (d, resp) = try await session.data(for: request)
            data = d
            httpStatus = (resp as? HTTPURLResponse)?.statusCode ?? 0
        } catch {
            voiceFetchError = "Network error: \(error.localizedDescription)"
            return
        }

        guard httpStatus == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            voiceFetchError = "API error \(httpStatus): \(body.prefix(120))"
            return
        }

        do {
            let decoded = try JSONDecoder().decode(ElevenLabsVoicesResponse.self, from: data)
            availableVoices = decoded.voices.sorted { $0.name < $1.name }
            if selectedElevenLabsVoiceID == nil {
                selectedElevenLabsVoiceID = availableVoices.first?.voice_id
            }
        } catch {
            voiceFetchError = "Decode error: \(error.localizedDescription)"
        }
    }

    // MARK: - ChatterBox TTS

    private func narrateWithChatterbox(_ text: String) async {
        let baseURL = chatterboxServerURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(baseURL)/audio/speech") else {
            print("[ChatterBox] Invalid URL: \(baseURL)/audio/speech")
            await narrateWithSystem(text)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120 // local model generation can be slow

        let body: [String: Any] = [
            "input": text,
            "voice": selectedChatterboxVoice ?? "default",
            "response_format": "wav"
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, response) = try await session.data(for: request)
            let httpStatus = (response as? HTTPURLResponse)?.statusCode ?? 0
            guard httpStatus == 200 else {
                print("[ChatterBox] Server returned \(httpStatus) — falling back to system TTS")
                chatterboxFailed = true
                await narrateWithSystem(text)
                return
            }

            audioPlayer = try AVAudioPlayer(data: data, fileTypeHint: "wav")
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            while audioPlayer?.isPlaying == true {
                try await Task.sleep(nanoseconds: 100_000_000)
            }
        } catch {
            print("[ChatterBox] Unreachable — falling back to system TTS for this session")
            chatterboxFailed = true
            await narrateWithSystem(text)
        }
    }

    // MARK: - ChatterBox Connection Check

    var chatterboxStatusDetail: String? = nil

    func checkChatterboxConnection() async {
        isCheckingChatterbox = true
        chatterboxStatusDetail = nil
        defer { isCheckingChatterbox = false }

        let baseURL = chatterboxServerURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(baseURL)/status") else {
            chatterboxConnectionStatus = .error
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 5

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                chatterboxConnectionStatus = .error
                return
            }
            // Parse status to check if model is loaded
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let modelLoaded = json["model_loaded"] as? Bool ?? false
                if modelLoaded {
                    chatterboxConnectionStatus = .connected
                    chatterboxFailed = false  // Reset — server is back
                } else {
                    chatterboxConnectionStatus = .error
                    let initError = json["initialization_error"] as? String
                    let initProgress = json["initialization_progress"] as? String
                    chatterboxStatusDetail = initError ?? initProgress ?? "Model not loaded"
                }
            } else {
                chatterboxConnectionStatus = .connected
            }
        } catch {
            chatterboxConnectionStatus = .unreachable
        }
    }

    // MARK: - Fetch ChatterBox Voices

    func fetchChatterboxVoices() async {
        chatterboxVoiceFetchError = nil
        isFetchingChatterboxVoices = true
        defer { isFetchingChatterboxVoices = false }

        let baseURL = chatterboxServerURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(baseURL)/voices") else {
            chatterboxVoiceFetchError = "Invalid server URL"
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        let data: Data
        let httpStatus: Int
        do {
            let (d, resp) = try await session.data(for: request)
            data = d
            httpStatus = (resp as? HTTPURLResponse)?.statusCode ?? 0
        } catch {
            chatterboxVoiceFetchError = "Network error: \(error.localizedDescription)"
            return
        }

        guard httpStatus == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            chatterboxVoiceFetchError = "Server error \(httpStatus): \(body.prefix(120))"
            return
        }

        do {
            let decoded = try JSONDecoder().decode([ChatterboxVoice].self, from: data)
            chatterboxVoices = decoded.sorted { $0.name < $1.name }
        } catch {
            // Try alternate response format: { "voices": [...] }
            struct WrappedResponse: Codable { let voices: [ChatterboxVoice] }
            if let wrapped = try? JSONDecoder().decode(WrappedResponse.self, from: data) {
                chatterboxVoices = wrapped.voices.sorted { $0.name < $1.name }
            } else {
                chatterboxVoiceFetchError = "Decode error: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Upload ChatterBox Voice

    func uploadChatterboxVoice(name: String, fileURL: URL) async {
        voiceUploadError = nil
        isUploadingVoice = true
        defer { isUploadingVoice = false }

        let baseURL = chatterboxServerURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: "\(baseURL)/voices") else {
            voiceUploadError = "Invalid server URL"
            return
        }

        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        guard let fileData = try? Data(contentsOf: fileURL) else {
            voiceUploadError = "Could not read audio file"
            return
        }

        let ext = fileURL.pathExtension.lowercased()
        let mimeType: String
        switch ext {
        case "mp3":  mimeType = "audio/mpeg"
        case "wav":  mimeType = "audio/wav"
        case "flac": mimeType = "audio/flac"
        case "m4a":  mimeType = "audio/mp4"
        case "ogg":  mimeType = "audio/ogg"
        default:     mimeType = "application/octet-stream"
        }

        var body = Data()
        // Name field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"name\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(name)\r\n".data(using: .utf8)!)
        // File field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        do {
            let (_, response) = try await session.data(for: request)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                voiceUploadError = "Upload failed (HTTP \(http.statusCode))"
            }
        } catch {
            voiceUploadError = "Upload error: \(error.localizedDescription)"
        }
    }

    // MARK: - System TTS Fallback

    private func narrateWithSystem(_ text: String) async {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = min(AVSpeechUtteranceMaximumSpeechRate, AVSpeechUtteranceDefaultSpeechRate * Float(speed))
        utterance.volume = volume
        synthesizer.speak(utterance)
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }

    // MARK: - Default Voice ID Fallback

    private func elevenLabsDefaultVoiceID() -> String {
        // Well-known ElevenLabs premade voice IDs as fallback
        switch voice {
        case .marcus: return "TxGEqnHWrfWFTfGW9XjX"
        case .aria:   return "EXAVITQu4vr4xnSDxMaL"
        case .nova:   return "jsCqWAovK2LkecY7zXl4"
        case .echo:   return "XrExE9yKIg1WjnnlVkGX"
        case .alloy:  return "pFZP5JQG7iQjIQuC4Bku"
        }
    }

    // MARK: - OpenAI Voice ID

    private func openAIVoiceID() -> String {
        switch voice {
        case .marcus: return "onyx"
        case .aria:   return "nova"
        case .nova:   return "nova"
        case .echo:   return "echo"
        case .alloy:  return "alloy"
        }
    }

    // MARK: - Test Voice

    func testVoice() async {
        await narrate("Hello! I'm your Monopoly AI Royal narrator. Let the games begin!")
    }
}
