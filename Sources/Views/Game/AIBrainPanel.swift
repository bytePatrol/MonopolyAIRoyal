import SwiftUI

struct AIBrainPanel: View {
    let playerID: String
    let reasoning: String
    let confidence: Double
    let state: GameState

    private var player: AIPlayer? {
        state.player(withID: playerID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            panelHeader

            // Thinking stream
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if reasoning.isEmpty {
                        waitingState
                    } else {
                        reasoningContent
                    }
                }
                .padding(14)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Footer: confidence + cost
            panelFooter
        }
        .background(Color.cardBackground)
    }

    // MARK: - Header

    private var panelHeader: some View {
        HStack {
            HStack(spacing: 8) {
                if let p = player {
                    PulsingDot(color: p.color, size: 6)
                    Text(p.name)
                        .font(.system(size: 12, weight: .black, design: .monospaced))
                        .foregroundStyle(p.color)
                }
                Text("AI BRAIN")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            Text("REASONING")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.25))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.04))
                .cornerRadius(4)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .overlay(Rectangle().fill(Color.cardBorder).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Waiting State

    private var waitingState: some View {
        VStack(spacing: 16) {
            Spacer()
            VStack(spacing: 8) {
                ThinkingDots(color: player?.color ?? .aiClaude)
                Text("Waiting for AI decision...")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Reasoning Content

    private var reasoningContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Color-coded reasoning sections
            let sections = parseReasoning(reasoning)
            ForEach(Array(sections.enumerated()), id: \.0) { _, section in
                reasoningSection(section)
            }
        }
    }

    private func reasoningSection(_ section: ReasoningSection) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if let label = section.label {
                Text(label.uppercased())
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(section.color.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(section.color.opacity(0.1))
                    .cornerRadius(3)
            }

            Text(section.text)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
                .lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Footer

    private var panelFooter: some View {
        HStack {
            // Confidence bar
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text("CONFIDENCE")
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                    Spacer()
                    Text("\(Int(confidence * 100))%")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundStyle(confidenceColor)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                        Rectangle()
                            .fill(confidenceColor)
                            .frame(width: geo.size.width * confidence)
                            .shadow(color: confidenceColor.opacity(0.5), radius: 3)
                    }
                    .frame(height: 3)
                    .cornerRadius(2)
                }
                .frame(height: 3)
            }
            .frame(maxWidth: .infinity)

            Spacer().frame(width: 12)

            // Decision badge
            if !reasoning.isEmpty {
                Text("DECIDED")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(.neonGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.neonGreen.opacity(0.1))
                    .cornerRadius(4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .overlay(Rectangle().fill(Color.cardBorder).frame(height: 1), alignment: .top)
    }

    private var confidenceColor: Color {
        confidence >= 0.8 ? .neonGreen : confidence >= 0.5 ? .neonAmber : .neonRed
    }

    // MARK: - Reasoning Parser

    struct ReasoningSection {
        var label: String?
        var text: String
        var color: Color
    }

    private func parseReasoning(_ text: String) -> [ReasoningSection] {
        // Simple parser: split on keywords to color-code
        let keywords: [(String, Color)] = [
            ("decision:", .neonGreen),
            ("risk:", .neonRed),
            ("strategy:", .neonViolet),
            ("analysis:", .neonCyan),
            ("confidence:", .neonAmber),
        ]

        for (kw, color) in keywords {
            if text.lowercased().contains(kw) {
                let parts = text.lowercased().components(separatedBy: kw)
                if parts.count >= 2 {
                    return [
                        ReasoningSection(label: nil, text: parts[0].capitalized, color: .white.opacity(0.7)),
                        ReasoningSection(label: kw.replacingOccurrences(of: ":", with: ""),
                                         text: parts[1...].joined(separator: kw).capitalized, color: color),
                    ]
                }
            }
        }

        return [ReasoningSection(label: nil, text: text, color: .white.opacity(0.8))]
    }
}
