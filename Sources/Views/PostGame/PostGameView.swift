import SwiftUI

struct PostGameView: View {
    @Environment(AppViewModel.self) private var appVM
    @Environment(PostGameViewModel.self) private var vm

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Confetti overlay
                    if vm.showConfetti {
                        ConfettiView()
                            .allowsHitTesting(false)
                            .frame(maxWidth: .infinity)
                            .frame(height: 300)
                    }

                    // Victory banner
                    VictoryBanner(winner: vm.winner, standings: vm.standings)

                    // Moments
                    MomentsSection(moments: vm.moments)
                        .padding(.top, 24)

                    // Interviews
                    InterviewsSection(interviews: vm.interviews)
                        .padding(.top, 24)

                    // Final standings
                    FinalStandingsTable(standings: vm.standings)
                        .padding(.top, 24)

                    // Highlight reel
                    HighlightReelSection()
                        .padding(.top, 24)

                    // Thumbnail
                    ThumbnailSection(title: vm.thumbnailTitle, subtitle: vm.thumbnailSubtitle)
                        .padding(.top, 24)

                    // Action bar
                    actionBar
                        .padding(.top, 32)
                        .padding(.bottom, 40)
                }
                .padding(.horizontal, 32)
            }
        }
        .onAppear {
            if vm.winner == nil {
                vm.loadMockResults()
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 16) {
            Button {
                appVM.lobbyViewModel.selectedPlayers = AIPlayer.mockPlayers
                appVM.navigate(to: .lobby)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                    Text("PLAY AGAIN")
                }
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(LinearGradient.violetToCyan)
                .cornerRadius(10)
            }
            .buttonStyle(.plain)
            .neonGlow(color: .aiClaude, radius: 12)

            Button {
                appVM.navigate(to: .stats)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                    Text("VIEW FULL STATS")
                }
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.06))
                .cornerRadius(10)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardBorder, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
}
