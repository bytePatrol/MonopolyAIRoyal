import SwiftUI

struct BudgetSection: View {
    @Environment(AdminViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm
        VStack(alignment: .leading, spacing: 20) {
            // Cost overview rings
            HStack(spacing: 24) {
                costRing(label: "PER DECISION", used: 0, limit: vm.settings.maxCostPerDecision, color: .neonCyan)
                costRing(label: "PER GAME", used: 0, limit: vm.settings.maxCostPerGame, color: .neonGreen)
                costRing(label: "PER DAY", used: 0, limit: vm.settings.maxCostPerDay, color: .neonAmber)
                costRing(label: "PER MONTH", used: 0, limit: vm.settings.maxCostPerMonth, color: .neonViolet)
            }
            .frame(maxWidth: .infinity)
            .padding(16)
            .glassCard(padding: 0, cornerRadius: 12)

            // Limit inputs
            adminGroup(title: "SPENDING LIMITS") {
                VStack(spacing: 14) {
                    limitRow("Max Cost Per Decision", value: $vm.settings.maxCostPerDecision, range: 0.01...1.0)
                    limitRow("Max Cost Per Game", value: $vm.settings.maxCostPerGame, range: 0.5...20.0)
                    limitRow("Max Cost Per Day", value: $vm.settings.maxCostPerDay, range: 1.0...100.0)
                    limitRow("Max Cost Per Month", value: $vm.settings.maxCostPerMonth, range: 5.0...500.0)
                }
            }

            // Cost table (per model)
            adminGroup(title: "MODEL COST REFERENCE") {
                VStack(spacing: 6) {
                    costTableRow(model: "Claude 3.5 Sonnet", inputCost: "3.00", outputCost: "15.00")
                    costTableRow(model: "GPT-4 Turbo", inputCost: "10.00", outputCost: "30.00")
                    costTableRow(model: "Gemini Pro 1.5", inputCost: "3.50", outputCost: "10.50")
                    costTableRow(model: "DeepSeek V3", inputCost: "0.14", outputCost: "0.28")
                    costTableRow(model: "LLaMA 3 70B", inputCost: "0.59", outputCost: "0.79")
                    costTableRow(model: "Mistral Large", inputCost: "4.00", outputCost: "12.00")
                }
            }
        }
    }

    private func costRing(label: String, used: Double, limit: Double, color: Color) -> some View {
        let percent = limit > 0 ? min(used / limit, 1.0) : 0
        return VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.1), lineWidth: 5)
                    .frame(width: 64, height: 64)
                Circle()
                    .trim(from: 0, to: percent)
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: color.opacity(0.4), radius: 4)

                VStack(spacing: 1) {
                    Text(String(format: "$%.2f", limit))
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(color)
                    Text("max")
                        .font(.system(size: 7, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }

            Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func limitRow(_ label: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("$")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
            TextField("", value: value, format: .number.precision(.fractionLength(2)))
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.neonViolet)
                .frame(width: 70)
                .padding(6)
                .background(Color.white.opacity(0.05))
                .cornerRadius(5)
        }
    }

    private func costTableRow(model: String, inputCost: String, outputCost: String) -> some View {
        HStack {
            Text(model)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.65))
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("$\(inputCost)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.neonGreen.opacity(0.8))
                .frame(width: 60, alignment: .trailing)
            Text("$\(outputCost)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.neonAmber.opacity(0.8))
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .overlay(Rectangle().fill(Color.cardBorder).frame(height: 0.5), alignment: .bottom)
    }

    private func adminGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
            content()
                .padding(14)
                .glassCard(padding: 0, cornerRadius: 10)
        }
    }
}
