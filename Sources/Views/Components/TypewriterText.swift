import SwiftUI

struct TypewriterText: View {
    let fullText: String
    var charDelay: TimeInterval = 0.02
    var font: Font = .system(size: 13, design: .monospaced)
    var color: Color = .white.opacity(0.9)

    @State private var displayedText: String = ""
    @State private var showCursor: Bool = true
    @State private var streamTask: Task<Void, Never>? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(displayedText)
                .font(font)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("|")
                .font(font)
                .foregroundStyle(color.opacity(showCursor ? 0.8 : 0))
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: showCursor)
        }
        .onChange(of: fullText) { _, newText in
            restartAnimation(for: newText)
        }
        .onAppear {
            showCursor = true
            restartAnimation(for: fullText)
        }
        .onDisappear {
            streamTask?.cancel()
        }
    }

    private func restartAnimation(for text: String) {
        streamTask?.cancel()
        displayedText = ""
        streamTask = Task {
            var index = text.startIndex
            while index < text.endIndex {
                guard !Task.isCancelled else { return }
                let nextIndex = text.index(after: index)
                let char = String(text[index..<nextIndex])
                await MainActor.run {
                    displayedText += char
                }
                index = nextIndex
                try? await Task.sleep(nanoseconds: UInt64(charDelay * 1_000_000_000))
            }
        }
    }
}

// MARK: - StreamingText (for OpenRouter SSE)

struct StreamingText: View {
    @Binding var text: String
    var font: Font = .system(size: 13, design: .monospaced)
    var color: Color = .white.opacity(0.9)

    @State private var showCursor = true

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(text)
                .font(font)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, alignment: .leading)

            if text.isEmpty || text.last != "." {
                Text("▊")
                    .font(font)
                    .foregroundStyle(color.opacity(showCursor ? 0.8 : 0))
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                            showCursor.toggle()
                        }
                    }
            }
        }
    }
}
