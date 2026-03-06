import SwiftUI
import Charts

struct StatsView: View {
    @Environment(StatsViewModel.self) private var vm

    var body: some View {
        VStack(spacing: 0) {
            // Header
            statsHeader

            // Tab bar
            tabBar

            // Content
            Group {
                switch vm.selectedTab {
                case .winProbability:
                    WinProbabilityTab()
                        .environment(vm)
                case .cashFlow:
                    CashFlowTab()
                        .environment(vm)
                case .propertyMap:
                    PropertyMapTab()
                        .environment(vm)
                case .leaderboard:
                    LeaderboardTab()
                        .environment(vm)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.appBackground)
        .onAppear { vm.refreshData() }
    }

    // MARK: - Header

    private var statsHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                GradientText(text: "ANALYTICS DASHBOARD",
                             gradient: .violetToCyan,
                             font: .system(size: 18, weight: .black, design: .monospaced))
                Text("ESPN-STYLE AI PERFORMANCE METRICS")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
            }
            Spacer()

            Button {
                vm.refreshData()
            } label: {
                HStack(spacing: 5) {
                    if vm.isLoading {
                        ProgressView().scaleEffect(0.6).tint(.white.opacity(0.6))
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text("REFRESH")
                }
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.04))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.cardBackground)
        .overlay(Rectangle().fill(Color.cardBorder).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        @Bindable var vm = vm
        return HStack(spacing: 0) {
            ForEach(StatsViewModel.StatsTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .background(Color.cardBackground)
        .overlay(Rectangle().fill(Color.cardBorder).frame(height: 1), alignment: .bottom)
    }

    private func tabButton(_ tab: StatsViewModel.StatsTab) -> some View {
        let isSelected = vm.selectedTab == tab
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                vm.selectedTab = tab
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 13))
                Text(tab.rawValue.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
            }
            .foregroundStyle(isSelected ? Color.neonViolet : Color.white.opacity(0.4))
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                isSelected
                    ? Color.neonViolet.opacity(0.08)
                    : Color.clear
            )
            .overlay(
                Rectangle()
                    .fill(isSelected ? Color.neonViolet : Color.clear)
                    .frame(height: 2),
                alignment: .bottom
            )
        }
        .buttonStyle(.plain)
    }
}
