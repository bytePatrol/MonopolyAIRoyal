import SwiftUI
import Charts

// MARK: - Endpoint data for chart annotations

private struct EndpointLabel: Identifiable {
    var id: String
    var x: Double
    var y: Double
    var colorHex: String
    var opacity: Double
    var isLeader: Bool
    var label: String
}

// MARK: - Win Probability Tab

struct WinProbabilityTab: View {
    @Environment(StatsViewModel.self) private var vm

    // MARK: - Computed helpers

    private var sortedSeries: [ChartSeries] {
        vm.winProbSeries.sorted { ($0.dataPoints.last?.y ?? 0) > ($1.dataPoints.last?.y ?? 0) }
    }

    private var leaderID: String? {
        sortedSeries.first?.playerID
    }

    private var bottomIDs: Set<String> {
        Set(sortedSeries.suffix(2).map(\.playerID))
    }

    private var leaderPoints: [ChartPoint] {
        sortedSeries.first?.dataPoints ?? []
    }

    private var leaderColorHex: String {
        sortedSeries.first?.colorHex ?? "#FFFFFF"
    }

    private var endpointLabels: [EndpointLabel] {
        vm.winProbSeries.compactMap { series in
            guard let last = series.dataPoints.last else { return nil }
            let isBottom = bottomIDs.contains(series.playerID)
            return EndpointLabel(
                id: series.playerID,
                x: last.x,
                y: last.y,
                colorHex: series.colorHex,
                opacity: isBottom ? 0.5 : 1.0,
                isLeader: series.playerID == leaderID,
                label: abbreviation(series.playerName)
            )
        }
    }

    private var previousRanks: [String: Int] {
        let lookback = 10
        let sorted = vm.winProbSeries.sorted { s1, s2 in
            let idx1 = max(0, s1.dataPoints.count - 1 - lookback)
            let idx2 = max(0, s2.dataPoints.count - 1 - lookback)
            let y1 = s1.dataPoints.indices.contains(idx1) ? s1.dataPoints[idx1].y : 0
            let y2 = s2.dataPoints.indices.contains(idx2) ? s2.dataPoints[idx2].y : 0
            return y1 > y2
        }
        var result: [String: Int] = [:]
        for (i, s) in sorted.enumerated() {
            result[s.playerID] = i + 1
        }
        return result
    }

    private func abbreviation(_ name: String) -> String {
        let parts = name.split(separator: " ")
        if let first = parts.first, first.count <= 5 {
            return String(first)
        }
        return String(name.prefix(4))
    }

    // MARK: - Chart

    private var winProbChart: some View {
        Chart {
            // Layer 1: Area fill under leader
            ForEach(leaderPoints) { point in
                AreaMark(
                    x: .value("Turn", point.x),
                    y: .value("Probability", point.y)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(hex: leaderColorHex).opacity(0.15),
                                 Color(hex: leaderColorHex).opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Layer 2: Line marks for all players
            ForEach(vm.winProbSeries) { series in
                let color = Color(hex: series.colorHex)
                let isLeader = series.playerID == leaderID
                let opacity: Double = bottomIDs.contains(series.playerID) ? 0.5 : 1.0
                let width: CGFloat = isLeader ? 3 : 2
                ForEach(series.dataPoints) { point in
                    LineMark(
                        x: .value("Turn", point.x),
                        y: .value("Probability", point.y)
                    )
                    .foregroundStyle(color.opacity(opacity))
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: width))
                }
            }

            // Layer 3: Endpoint dots + inline labels
            ForEach(endpointLabels) { ep in
                PointMark(
                    x: .value("Turn", ep.x),
                    y: .value("Probability", ep.y)
                )
                .foregroundStyle(Color(hex: ep.colorHex).opacity(ep.opacity))
                .symbolSize(ep.isLeader ? 40 : 25)
                .annotation(position: .trailing, spacing: 4) {
                    Text(ep.label)
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: ep.colorHex).opacity(ep.opacity))
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 10)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.white.opacity(0.1))
                AxisValueLabel()
                    .foregroundStyle(Color.white.opacity(0.5))
                    .font(.system(size: 9, design: .monospaced))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .stride(by: 10)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.white.opacity(0.1))
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("\(Int(v))%")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.5))
                    }
                }
            }
        }
        .chartLegend(.hidden)
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 0) {
            // Chart
            VStack(alignment: .leading, spacing: 12) {
                Text("WIN PROBABILITY OVER TURNS")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                winProbChart
                    .padding(.leading, 20)
                    .padding(.trailing, 50)
                    .padding(.bottom, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.cardBackground)
            .overlay(Rectangle().fill(Color.cardBorder).frame(width: 1), alignment: .trailing)

            // Right: Probability cards
            ScrollView {
                VStack(spacing: 10) {
                    Text("CURRENT ODDS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(Array(sortedSeries.enumerated()), id: \.element.id) { rank, series in
                        WinProbCard(
                            series: series,
                            rank: rank + 1,
                            previousRank: previousRanks[series.playerID] ?? (rank + 1)
                        )
                    }

                    Divider()
                        .background(Color.cardBorder)
                        .padding(.top, 8)

                    Text("STORYLINES")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)

                    ForEach(vm.storylines) { story in
                        StorylineCard(story: story)
                    }
                }
                .padding(16)
            }
            .frame(width: 260)
            .background(Color.appBackground)
        }
    }
}

// MARK: - Mini Sparkline

struct MiniSparkline: View {
    let points: [ChartPoint]
    let color: Color

    var body: some View {
        Chart {
            ForEach(points) { point in
                LineMark(
                    x: .value("T", point.x),
                    y: .value("P", point.y)
                )
                .foregroundStyle(color.opacity(0.6))
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .frame(height: 20)
    }
}

// MARK: - Win Prob Card

struct WinProbCard: View {
    let series: ChartSeries
    let rank: Int
    let previousRank: Int

    private var currentProb: Double {
        series.dataPoints.last?.y ?? 0
    }

    private var probFrom10TurnsAgo: Double {
        let idx = max(0, series.dataPoints.count - 11)
        return series.dataPoints.indices.contains(idx) ? series.dataPoints[idx].y : currentProb
    }

    private var isUp: Bool? {
        let diff = currentProb - probFrom10TurnsAgo
        if abs(diff) < 0.5 { return nil }
        return diff > 0
    }

    private var sparklinePoints: [ChartPoint] {
        Array(series.dataPoints.suffix(15))
    }

    private var rankChangeText: String {
        if rank < previousRank { return "▲" }
        if rank > previousRank { return "▼" }
        return "—"
    }

    private var rankChangeColor: Color {
        if rank < previousRank { return .green }
        if rank > previousRank { return .red }
        return .white.opacity(0.3)
    }

    private var trendColor: Color {
        guard let up = isUp else { return Color(hex: series.colorHex) }
        return up ? .green : .red
    }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: series.colorHex))
                        .frame(width: 10, height: 10)
                        .neonGlow(color: Color(hex: series.colorHex), radius: 6)
                    Text(series.playerName)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.8))
                }
                Spacer()
                HStack(spacing: 4) {
                    Text(rankChangeText)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(rankChangeColor)
                    Text(String(format: "%.1f%%", currentProb))
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundStyle(trendColor)
                }
            }

            MiniSparkline(points: sparklinePoints, color: Color(hex: series.colorHex))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: series.colorHex).opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: series.colorHex).opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Storyline Card

struct StorylineCard: View {
    let story: Storyline

    private var typeColor: Color {
        switch story.type {
        case .dominance: return .aiClaude
        case .rivalry:   return .aiGPT4
        case .comeback:  return .neonGreen
        case .streak:    return .neonRed
        }
    }

    private var typeLabel: String {
        switch story.type {
        case .dominance: return "DOMINANCE"
        case .rivalry:   return "RIVALRY"
        case .comeback:  return "COMEBACK"
        case .streak:    return "STREAK"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(typeLabel)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundStyle(typeColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(typeColor.opacity(0.15))
                    .cornerRadius(3)
                Spacer()
            }
            Text(story.title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.85))
            Text(story.description)
                .font(.system(size: 10))
                .foregroundStyle(.white.opacity(0.5))
                .lineSpacing(2)
        }
        .padding(10)
        .glassCard(padding: 0, cornerRadius: 8)
    }
}
