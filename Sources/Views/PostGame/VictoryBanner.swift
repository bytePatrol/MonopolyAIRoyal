import SwiftUI

struct VictoryBanner: View {
    let winner: AIPlayer?
    let standings: [FinalStanding]

    var body: some View {
        VStack(spacing: 24) {
            // Winner announcement
            if let winner = winner {
                VStack(spacing: 8) {
                    Text("🏆 VICTORY")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.top, 32)

                    Text(winner.name)
                        .font(.system(size: 48, weight: .black, design: .monospaced))
                        .foregroundStyle(winner.color)
                        .neonText(color: winner.color, glowRadius: 20)
                        .shadow(color: winner.color.opacity(0.4), radius: 30)

                    Text("WINS THE MONOPOLY AI ROYAL!")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                        .tracking(3)

                    Text(winner.personality.rawValue)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(winner.color.opacity(0.7))
                }
            }

            // Quick stats grid
            if let first = standings.first {
                HStack(spacing: 24) {
                    quickStat(label: "FINAL NET WORTH",
                              value: "$\(first.finalNetWorth.formatted())",
                              color: first.player.color)
                    quickStat(label: "PROPERTIES OWNED",
                              value: "\(first.propertiesOwned)",
                              color: .neonGreen)
                    quickStat(label: "HOTELS BUILT",
                              value: "\(first.hotelsBuilt)",
                              color: .neonAmber)
                    quickStat(label: "RENT COLLECTED",
                              value: "$\(first.rentCollected.formatted())",
                              color: .neonCyan)
                    if standings.count > 1 {
                        let second = standings[1]
                        quickStat(label: "RUNNER-UP",
                                  value: second.player.name,
                                  color: second.player.color)
                    }
                }
                .padding(20)
                .background(Color.cardBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(first.player.color.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func quickStat(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .black, design: .monospaced))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }
}
