import SwiftUI

struct AddPlayerSheet: View {
    @Environment(LobbyViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm
        VStack(spacing: 0) {
            // Header
            sheetHeader

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Name
                    nameSection

                    // Model picker
                    modelSection

                    // Personality
                    personalitySection

                    // Color
                    colorSection

                    // Preview
                    if vm.newPlayerModel != nil && !vm.newPlayerName.isEmpty {
                        previewSection
                    }
                }
                .padding(20)
            }

            // Action bar
            actionBar
        }
        .frame(width: 520, height: 620)
        .background(Color.appBackground)
    }

    // MARK: - Header

    private var sheetHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("ADD AI PLAYER")
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                Text("Choose a model from OpenRouter's 200+ catalog")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }
            Spacer()
            Button {
                vm.showAddPlayerSheet = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white.opacity(0.4))
                    .frame(width: 28, height: 28)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.cardBackground)
        .overlay(Rectangle().fill(Color.cardBorder).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Name

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("PLAYER NAME")
            TextField("e.g. QWEN 2.5, DBRX, COHERE...", text: Bindable(vm).newPlayerName)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .padding(12)
                .background(Color.white.opacity(0.04))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cardBorder))
        }
    }

    // MARK: - Model

    private var modelSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                sectionLabel("AI MODEL")
                Spacer()
                if vm.isLoadingModels {
                    HStack(spacing: 6) {
                        ProgressView().scaleEffect(0.6).tint(.white.opacity(0.5))
                        Text("Loading models...")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                } else {
                    Text("\(vm.availableModels.count) models")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                }
            }

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.white.opacity(0.3))
                    .font(.system(size: 11))
                TextField("Search models...", text: Bindable(vm).modelSearchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
            }
            .padding(10)
            .background(Color.white.opacity(0.04))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cardBorder))

            // Model list
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(vm.filteredModels.prefix(50)) { model in
                        modelRow(model: model)
                    }
                    if vm.filteredModels.isEmpty && !vm.isLoadingModels {
                        Text("No models found")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.3))
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(height: 140)
            .background(Color.white.opacity(0.02))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cardBorder))
        }
    }

    private func modelRow(model: OpenRouterModel) -> some View {
        let isSelected = vm.newPlayerModel?.id == model.id
        return Button {
            vm.newPlayerModel = model
            if vm.newPlayerName.isEmpty {
                // Auto-fill name from model
                let name = model.name
                    .replacingOccurrences(of: " (free)", with: "")
                    .replacingOccurrences(of: " (self-moderated)", with: "")
                vm.newPlayerName = name
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(model.name)
                        .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .monospaced))
                        .foregroundStyle(isSelected ? Color(hex: vm.newPlayerColorHex) : .white.opacity(0.7))
                        .lineLimit(1)
                    Text(model.id)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.25))
                        .lineLimit(1)
                }
                Spacer()
                Text(model.displayCost)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(model.promptCostPer1M == 0 ? .neonGreen : .neonAmber)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.neonGreen)
                        .font(.system(size: 12))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.white.opacity(0.06) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Personality

    private var personalitySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("PERSONALITY")
            HStack(spacing: 6) {
                ForEach(AIPersonality.allCases, id: \.rawValue) { personality in
                    let isSelected = vm.newPlayerPersonality == personality
                    Button {
                        vm.newPlayerPersonality = personality
                    } label: {
                        Text(personalityShort(personality))
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(isSelected ? .white : .white.opacity(0.5))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color(hex: vm.newPlayerColorHex).opacity(0.3) : Color.white.opacity(0.04))
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(isSelected ? Color(hex: vm.newPlayerColorHex).opacity(0.6) : Color.cardBorder, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func personalityShort(_ p: AIPersonality) -> String {
        switch p {
        case .aggressive:   return "AGGRO"
        case .conservative: return "CONSERV"
        case .mathematical: return "MATH"
        case .tradeShark:   return "TRADER"
        case .chaoticEvil:  return "CHAOS"
        case .balanced:     return "BALANCED"
        }
    }

    // MARK: - Color

    private var colorSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("COLOR")
            HStack(spacing: 8) {
                ForEach(LobbyViewModel.playerColorOptions, id: \.hex) { option in
                    let isSelected = vm.newPlayerColorHex == option.hex
                    Button {
                        vm.newPlayerColorHex = option.hex
                    } label: {
                        Circle()
                            .fill(Color(hex: option.hex))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: isSelected ? 2 : 0)
                            )
                            .neonGlow(color: Color(hex: option.hex), radius: isSelected ? 8 : 0)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Preview

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            sectionLabel("PREVIEW")
            HStack(spacing: 12) {
                Circle()
                    .fill(Color(hex: vm.newPlayerColorHex))
                    .frame(width: 32, height: 32)
                    .neonGlow(color: Color(hex: vm.newPlayerColorHex), radius: 10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.newPlayerName.uppercased())
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundStyle(Color(hex: vm.newPlayerColorHex))
                    Text("\(vm.newPlayerPersonality.rawValue) | \(vm.newPlayerModel?.id ?? "")")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                        .lineLimit(1)
                }
                Spacer()
                Text(vm.newPlayerModel?.displayCost ?? "")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.neonAmber)
            }
            .padding(12)
            .background(Color(hex: vm.newPlayerColorHex).opacity(0.05))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: vm.newPlayerColorHex).opacity(0.3)))
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack {
            Button {
                vm.showAddPlayerSheet = false
            } label: {
                Text("CANCEL")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                vm.addPlayer()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("ADD PLAYER")
                }
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(canAdd ? LinearGradient.violetToCyan : LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .leading, endPoint: .trailing))
                )
            }
            .buttonStyle(.plain)
            .disabled(!canAdd)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .overlay(Rectangle().fill(Color.cardBorder).frame(height: 1), alignment: .top)
    }

    private var canAdd: Bool {
        vm.newPlayerModel != nil && !vm.newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundStyle(.white.opacity(0.4))
    }
}
