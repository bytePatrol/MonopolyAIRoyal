import SwiftUI

struct LobbyView: View {
    @Environment(AppViewModel.self) private var appVM
    @Environment(LobbyViewModel.self) private var vm

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            lobbyTopBar

            // Main content
            HStack(spacing: 16) {
                // Left: AI Fighter Cards grid
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(vm.availablePlayers) { player in
                            playerCard(player)
                        }

                        // Add player card
                        addPlayerCard
                    }
                    .padding(16)
                }
                .frame(maxWidth: .infinity)

                // Right: Trash Talk Panel
                TrashTalkPanel()
                    .frame(width: 320)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Action bar
            actionBar
        }
        .background(Color.appBackground)
        .sheet(isPresented: Bindable(vm).showAddPlayerSheet) {
            AddPlayerSheet()
                .environment(vm)
        }
    }

    // MARK: - Player Card with Remove

    private func playerCard(_ player: AIPlayer) -> some View {
        AIFighterCard(player: player, isSelected: vm.isSelected(player)) {
            vm.togglePlayer(player)
        }
        .overlay(alignment: .topTrailing) {
            // Allow removing any player as long as at least 2 remain in the roster
            if vm.availablePlayers.count > 2 {
                Button {
                    vm.removePlayer(player)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.neonRed)
                        .background(Circle().fill(Color.appBackground).padding(2))
                }
                .buttonStyle(.plain)
                .offset(x: 6, y: -6)
            }
        }
    }

    // MARK: - Add Player Card

    private var addPlayerCard: some View {
        Button {
            vm.openAddPlayer()
        } label: {
            VStack(spacing: 12) {
                Spacer()
                Image(systemName: "plus.circle")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.white.opacity(0.25))
                Text("ADD AI PLAYER")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
                Text("Choose from 200+ OpenRouter models")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.2))
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .fill(Color.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.lg)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [8, 6]))
                    .foregroundStyle(Color.white.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Top Bar

    private var lobbyTopBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    GradientText(text: "MONOPOLY AI ROYAL", gradient: .violetToCyan,
                                 font: .system(size: 22, weight: .black, design: .monospaced))
                    Text("V7")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                }
                Text("SELECT YOUR AI WARRIORS")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
            }

            Spacer()

            HStack(spacing: 12) {
                // Selected count
                HStack(spacing: 6) {
                    ForEach(vm.selectedPlayers) { p in
                        Circle()
                            .fill(p.color)
                            .frame(width: 10, height: 10)
                            .neonGlow(color: p.color, radius: 6)
                    }
                }

                Text("\(vm.selectedPlayers.count) SELECTED")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .glassCard(padding: 10, cornerRadius: 10)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.cardBackground)
        .overlay(Rectangle().fill(Color.cardBorder).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack {
            // Game config summary
            HStack(spacing: 24) {
                configItem(label: "FORMAT", value: vm.gameConfig.format.rawValue)
                configItem(label: "MAX TURNS", value: "\(vm.gameConfig.maxTurns)")
                configItem(label: "STARTING $", value: "$\(vm.gameConfig.startingCash)")
            }

            Spacer()

            // Trash talk button
            Button {
                Task { await vm.generateTrashTalk() }
            } label: {
                HStack(spacing: 6) {
                    if vm.isGeneratingTrashTalk {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                    }
                    Text("GENERATE TRASH TALK")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.06))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.7))

            // START button
            Button {
                Task {
                    await vm.startCountdown()
                    appVM.startGame()
                }
            } label: {
                HStack(spacing: 8) {
                    if let count = vm.countdown {
                        Text("\(count)")
                            .font(.system(size: 20, weight: .black, design: .monospaced))
                    } else {
                        Image(systemName: "play.fill")
                        Text("START GAME")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(LinearGradient.violetToCyan)
                )
            }
            .buttonStyle(.plain)
            .neonGlow(color: .aiClaude, radius: 20)
            .disabled(vm.selectedPlayers.count < 2 || vm.isCountingDown)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .overlay(Rectangle().fill(Color.cardBorder).frame(height: 1), alignment: .top)
    }

    private func configItem(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}
