import SwiftUI
import Observation

enum AppScreen: String, CaseIterable {
    case lobby    = "lobby"
    case game     = "game"
    case stats    = "stats"
    case admin    = "admin"
    case postGame = "postGame"

    var title: String {
        switch self {
        case .lobby:    return "Lobby"
        case .game:     return "Game"
        case .stats:    return "Stats"
        case .admin:    return "Admin"
        case .postGame: return "Post-Game"
        }
    }

    var systemImage: String {
        switch self {
        case .lobby:    return "gamecontroller.fill"
        case .game:     return "play.fill"
        case .stats:    return "chart.bar.fill"
        case .admin:    return "gearshape.fill"
        case .postGame: return "trophy.fill"
        }
    }
}

@Observable
@MainActor
final class AppViewModel {
    var currentScreen: AppScreen = .lobby
    var totalCost: Double = 0.0

    // Child ViewModels
    let lobbyViewModel   = LobbyViewModel()
    let gameViewModel    = GameViewModel()
    let statsViewModel   = StatsViewModel()
    let adminViewModel   = AdminViewModel()
    let postGameViewModel = PostGameViewModel()

    // Services (shared)
    let costTracker = CostTracker()
    let database    = DatabaseService.shared

    init() {
        // Wire up cost tracker
        gameViewModel.costTracker = costTracker
    }

    func navigate(to screen: AppScreen) {
        withAnimation(.easeInOut(duration: 0.2)) {
            currentScreen = screen
        }
    }

    func startGame() {
        gameViewModel.startNewGame(players: lobbyViewModel.selectedPlayers)
        navigate(to: .game)
    }

    func endGame() {
        let results = gameViewModel.buildGameResults()
        postGameViewModel.loadResults(results)
        statsViewModel.refreshData()
        navigate(to: .postGame)
    }
}
