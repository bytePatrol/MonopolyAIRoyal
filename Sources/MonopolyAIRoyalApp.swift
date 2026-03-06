import SwiftUI

@main
struct MonopolyAIRoyalApp: App {
    @State private var appViewModel = AppViewModel()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appViewModel)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 1440, height: 900)
        .commands {
            CommandGroup(replacing: .help) {
                Button("MonopolyAIRoyal Help") {
                    openWindow(id: "help")
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }

        Window("MonopolyAIRoyal Help", id: "help") {
            HelpView()
                .preferredColorScheme(.dark)
        }
        .defaultSize(width: 820, height: 700)
        .windowResizability(.contentSize)
    }
}

struct RootView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        HStack(spacing: 0) {
            SidebarView()
            Divider()
                .background(Color.white.opacity(0.08))

            Group {
                switch appVM.currentScreen {
                case .lobby:
                    LobbyView()
                        .environment(appVM.lobbyViewModel)
                case .game:
                    GameView()
                        .environment(appVM.gameViewModel)
                case .stats:
                    StatsView()
                        .environment(appVM.statsViewModel)
                case .admin:
                    AdminView()
                        .environment(appVM.adminViewModel)
                case .postGame:
                    PostGameView()
                        .environment(appVM.postGameViewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.appBackground)
        .frame(minWidth: 1280, minHeight: 800)
    }
}
