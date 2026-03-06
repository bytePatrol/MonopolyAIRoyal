import SwiftUI

struct GameView: View {
    @Environment(AppViewModel.self) private var appVM
    @Environment(GameViewModel.self) private var vm

    var body: some View {
        VStack(spacing: 0) {
            // Top status bar
            gameTopBar

            // Main layout: Players | Board | Right Panel
            HStack(spacing: 0) {
                PlayerSidebarView(state: vm.gameState)
                    .frame(width: 240)

                Divider().background(Color.cardBorder)

                // Board centered
                ScrollView([.horizontal, .vertical]) {
                    BoardView(state: vm.gameState)
                        .padding(24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider().background(Color.cardBorder)

                // Right panel
                VStack(spacing: 0) {
                    AIBrainPanel(
                        playerID: vm.activePlayerID,
                        reasoning: vm.activePlayerReasoning,
                        confidence: vm.reasoningConfidence,
                        state: vm.gameState
                    )
                    .frame(maxHeight: .infinity)

                    Divider().background(Color.cardBorder)

                    CommentaryPanel(
                        entries: vm.commentary,
                        isNarrating: NarratorService.shared.isSpeaking
                    )
                    .frame(height: 220)
                }
                .frame(width: 320)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.appBackground)
        .onAppear {
            // Start mock game if not already running
            if !vm.isGameRunning {
                vm.gameState = GameState.mockState()
            }
        }
    }

    // MARK: - Top Bar

    private var gameTopBar: some View {
        HStack {
            // Turn info
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 1) {
                    Text("TURN \(vm.gameState.turn)")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .foregroundStyle(.neonViolet)
                    Text("of \(vm.gameState.activePlayers.count) players active")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))
                }

                // Phase indicator
                phaseBadge
            }

            Spacer()

            // Controls
            HStack(spacing: 8) {
                // Speed selector
                Menu {
                    Button("Slow")    { vm.setSpeed(.slow) }
                    Button("Normal")  { vm.setSpeed(.normal) }
                    Button("Fast")    { vm.setSpeed(.fast) }
                    Button("Instant") { vm.setSpeed(.instant) }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "speedometer")
                        Text(speedLabel)
                    }
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)

                // Pause/Resume
                Button {
                    vm.togglePause()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: vm.isPaused ? "play.fill" : "pause.fill")
                        Text(vm.isPaused ? "RESUME" : "PAUSE")
                    }
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(vm.isPaused ? .neonGreen : .white.opacity(0.7))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(
                        vm.isPaused ? Color.neonGreen.opacity(0.4) : Color.clear, lineWidth: 1))
                }
                .buttonStyle(.plain)

                // End game
                Button {
                    vm.stopGame()
                    appVM.endGame()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "stop.fill")
                        Text("END GAME")
                    }
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.neonRed.opacity(0.8))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.neonRed.opacity(0.08))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.neonRed.opacity(0.25), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.cardBackground)
        .overlay(Rectangle().fill(Color.cardBorder).frame(height: 1), alignment: .bottom)
    }

    private var phaseBadge: some View {
        let (text, color) = phaseInfo
        return HStack(spacing: 4) {
            PulsingDot(color: color, size: 5)
            Text(text)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(5)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(color.opacity(0.25), lineWidth: 1))
    }

    private var phaseInfo: (String, Color) {
        switch vm.gameState.phase {
        case .rolling:     return ("ROLLING", .neonAmber)
        case .moving:      return ("MOVING",  .neonCyan)
        case .action:      return ("ACTION",  .neonGreen)
        case .aiDeciding:  return ("AI THINKING", .neonViolet)
        case .trading:     return ("TRADING", .neonPink)
        case .building:    return ("BUILDING", .neonGreen)
        case .gameOver:    return ("GAME OVER", .neonRed)
        case .setup:       return ("SETUP", .white.opacity(0.5))
        }
    }

    private var speedLabel: String {
        switch vm.gameSpeed {
        case .slow:    return "SLOW"
        case .normal:  return "NORMAL"
        case .fast:    return "FAST"
        case .instant: return "INSTANT"
        }
    }
}
