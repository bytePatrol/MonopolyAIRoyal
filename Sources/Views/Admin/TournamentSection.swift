import SwiftUI

struct TournamentSection: View {
    @Environment(AdminViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm
        VStack(alignment: .leading, spacing: 20) {
            adminGroup(title: "TOURNAMENT FORMAT") {
                VStack(spacing: 12) {
                    ForEach(TournamentFormat.allCases, id: \.self) { format in
                        formatCard(format, isSelected: vm.settings.tournamentFormat == format) {
                            vm.settings.tournamentFormat = format
                        }
                    }
                }
            }

            if vm.settings.tournamentFormat != .single {
                adminGroup(title: "SERIES LENGTH") {
                    HStack {
                        Text("Games per series")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Stepper(value: $vm.settings.seriesLength, in: 2...9, step: 1) {
                            Text("\(vm.settings.seriesLength)")
                                .font(.system(size: 14, weight: .black, design: .monospaced))
                                .foregroundStyle(.neonViolet)
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
            }
        }
    }

    private func formatCard(_ format: TournamentFormat, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(format.rawValue.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(isSelected ? .neonViolet : .white.opacity(0.7))
                    Text(formatDescription(format))
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.neonViolet)
                }
            }
            .padding(12)
            .background(isSelected ? Color.neonViolet.opacity(0.08) : Color.white.opacity(0.02))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.neonViolet.opacity(0.4) : Color.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func formatDescription(_ format: TournamentFormat) -> String {
        switch format {
        case .single:     return "One decisive game — winner takes all"
        case .bestOf3:    return "Best of 3 games — first to 2 wins"
        case .bestOf5:    return "Best of 5 games — first to 3 wins"
        case .roundRobin: return "Every AI plays every other AI"
        case .swiss:      return "Paired by similar performance, 5 rounds"
        }
    }

    private func adminGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
            content()
        }
    }
}
