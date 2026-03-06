import SwiftUI

struct ModelsSection: View {
    @Environment(AdminViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm
        VStack(alignment: .leading, spacing: 20) {
            // Mock mode toggle
            adminToggle(
                label: "Mock Mode",
                description: "Use scripted AI decisions — no API calls, instant gameplay",
                isOn: $vm.settings.mockMode,
                color: .neonAmber
            )

            if vm.settings.mockMode {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.neonAmber)
                    Text("Mock Mode is active — AI decisions are scripted, no API costs.")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(12)
                .background(Color.neonAmber.opacity(0.08))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.neonAmber.opacity(0.2)))
            }

            Divider().background(Color.cardBorder)

            // Player model configuration
            VStack(alignment: .leading, spacing: 12) {
                Text("PLAYER MODEL ASSIGNMENT")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))

                ForEach(AIPlayer.mockPlayers) { player in
                    playerModelRow(player: player)
                }
            }

            Divider().background(Color.cardBorder)

            // Model catalog
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("MODEL CATALOG")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))
                    Spacer()
                    Button {
                        Task { await vm.fetchModels() }
                    } label: {
                        HStack(spacing: 5) {
                            if vm.isLoadingModels {
                                ProgressView().scaleEffect(0.6).tint(.white.opacity(0.5))
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text("FETCH MODELS")
                        }
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.neonCyan.opacity(0.8))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.neonCyan.opacity(0.08))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }

                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white.opacity(0.3))
                    TextField("Search models...", text: $vm.modelSearchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                }
                .padding(10)
                .background(Color.white.opacity(0.04))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cardBorder, lineWidth: 1))

                // Model list
                LazyVStack(spacing: 4) {
                    ForEach(vm.filteredModels.prefix(20)) { model in
                        modelCatalogRow(model: model)
                    }
                    if vm.availableModels.isEmpty && !vm.isLoadingModels {
                        Text("Tap 'Fetch Models' to load the OpenRouter catalog (200+ models)")
                            .font(.system(size: 11))
                            .foregroundStyle(.white.opacity(0.3))
                            .padding(.vertical, 20)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func adminToggle(label: String, description: String, isOn: Binding<Bool>, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(label.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                Text(description)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle(tint: color))
                .labelsHidden()
        }
        .padding(14)
        .glassCard(padding: 0, cornerRadius: 10)
    }

    private func playerModelRow(player: AIPlayer) -> some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(player.color)
                    .frame(width: 10, height: 10)
                    .neonGlow(color: player.color, radius: 4)
                Text(player.name)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(player.color)
            }
            Spacer()
            Text(player.model)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cardBorder, lineWidth: 1))
    }

    private func modelCatalogRow(model: OpenRouterModel) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.name)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                Text(model.id)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }
            Spacer()
            Text(model.displayCost)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(model.promptCostPer1M == 0 ? .neonGreen : .neonAmber)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.02))
        .cornerRadius(5)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.cardBorder, lineWidth: 0.5))
    }
}
