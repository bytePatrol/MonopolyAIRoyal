import Foundation
import Observation

// MARK: - Streaming Service (ScreenCaptureKit + RTMP stub)
// Full implementation requires HaishinKit package for RTMP.
// This is a functional stub that shows streaming status without actual encoding.

@Observable
@MainActor
final class StreamingService {
    static let shared = StreamingService()

    var isStreaming: Bool = false
    var viewerCount: Int = 0
    var bitrate: Int = 0
    var streamDuration: TimeInterval = 0
    var statusMessage: String = "Ready to stream"
    var platform: StreamPlatform = .youtube

    private var startTime: Date?
    private var durationTimer: Task<Void, Never>?

    private init() {}

    // MARK: - Start Streaming

    func startStream(settings: AppSettings) async throws {
        guard !isStreaming else { return }

        // In a real implementation, use ScreenCaptureKit to capture screen
        // and HaishinKit to push RTMP to the configured endpoint.

        statusMessage = "Connecting to \(settings.streamPlatform.rawValue)..."
        try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate connection

        isStreaming = true
        startTime = Date()
        platform = settings.streamPlatform
        statusMessage = "🔴 LIVE on \(settings.streamPlatform.rawValue)"
        viewerCount = Int.random(in: 50...200)
        bitrate = settings.videoBitrate

        startDurationTimer()
        startSimulatedViewerGrowth()
    }

    // MARK: - Stop Streaming

    func stopStream() {
        isStreaming = false
        durationTimer?.cancel()
        durationTimer = nil
        statusMessage = "Stream ended"
        bitrate = 0
    }

    // MARK: - Timers

    private func startDurationTimer() {
        durationTimer = Task {
            while isStreaming {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if let start = startTime {
                    streamDuration = Date().timeIntervalSince(start)
                }
            }
        }
    }

    private func startSimulatedViewerGrowth() {
        Task {
            while isStreaming {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                viewerCount += Int.random(in: -5...20)
                viewerCount = max(0, viewerCount)
            }
        }
    }

    // MARK: - Display

    var formattedDuration: String {
        let hours = Int(streamDuration) / 3600
        let minutes = (Int(streamDuration) % 3600) / 60
        let seconds = Int(streamDuration) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedViewers: String {
        viewerCount >= 1000
            ? String(format: "%.1fK", Double(viewerCount) / 1000)
            : "\(viewerCount)"
    }

    var formattedBitrate: String {
        "\(bitrate / 1000)Mbps"
    }
}
