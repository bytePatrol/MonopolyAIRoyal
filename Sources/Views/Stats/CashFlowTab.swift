import SwiftUI
import Charts

struct CashFlowTab: View {
    @Environment(StatsViewModel.self) private var vm

    var body: some View {
        HStack(spacing: 0) {
            // Main chart area
            VStack(alignment: .leading, spacing: 0) {
                chartHeader
                areaChart
                metricsRow
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.cardBackground)
            .overlay(Rectangle().fill(Color.cardBorder).frame(width: 1), alignment: .trailing)

            // Right panel: efficiency bars
            ScrollView {
                VStack(spacing: 12) {
                    Text("GROUP EFFICIENCY")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(ColorGroup.allCases, id: \.self) { group in
                        groupEfficiencyBar(group: group)
                    }
                }
                .padding(16)
            }
            .frame(width: 220)
            .background(Color.appBackground)
        }
    }

    private var chartHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("NET WORTH TRAJECTORY")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
            Text("Cash + property value over game turns")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private var areaChart: some View {
        Chart {
            ForEach(vm.cashFlowSeries) { series in
                ForEach(series.dataPoints) { point in
                    AreaMark(
                        x: .value("Turn", point.x),
                        y: .value("Net Worth", point.y)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: series.colorHex).opacity(0.3), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    LineMark(
                        x: .value("Turn", point.x),
                        y: .value("Net Worth", point.y)
                    )
                    .foregroundStyle(Color(hex: series.colorHex))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                    .interpolationMethod(.catmullRom)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: 10)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.white.opacity(0.06))
                AxisValueLabel()
                    .foregroundStyle(Color.white.opacity(0.35))
                    .font(.system(size: 9, design: .monospaced))
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.white.opacity(0.06))
                AxisValueLabel {
                    if let v = value.as(Double.self) {
                        Text("$\(Int(v))")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(Color.white.opacity(0.35))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 280)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private var metricsRow: some View {
        HStack(spacing: 16) {
            ForEach(vm.cashFlowSeries.prefix(6)) { series in
                VStack(spacing: 3) {
                    Circle()
                        .fill(Color(hex: series.colorHex))
                        .frame(width: 8, height: 8)
                    Text(series.playerName.prefix(6) + (series.playerName.count > 6 ? "..." : ""))
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("$\(Int(series.dataPoints.last?.y ?? 0))")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(hex: series.colorHex))
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.02))
        .overlay(Rectangle().fill(Color.cardBorder).frame(height: 1), alignment: .top)
    }

    private func groupEfficiencyBar(group: ColorGroup) -> some View {
        VStack(spacing: 4) {
            HStack {
                Circle()
                    .fill(group.color)
                    .frame(width: 8, height: 8)
                Text(group.rawValue.uppercased())
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Text("$\(group.houseCost)/house")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }
            let efficiency = Double.random(in: 0.3...0.95) // Mock
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 4)
                    Rectangle()
                        .fill(group.color)
                        .frame(width: geo.size.width * efficiency, height: 4)
                        .shadow(color: group.color.opacity(0.5), radius: 2)
                }
                .cornerRadius(2)
            }
            .frame(height: 4)
        }
    }
}
