import SwiftUI

struct SidebarView: View {
    @Environment(AppViewModel.self) private var appVM

    var body: some View {
        @Bindable var vm = appVM
        VStack(spacing: 0) {
            // Logo
            logoView
                .padding(.top, 20)
                .padding(.bottom, 24)

            // Navigation items
            VStack(spacing: 6) {
                ForEach(AppScreen.allCases, id: \.self) { screen in
                    SidebarNavItem(
                        screen: screen,
                        isActive: appVM.currentScreen == screen
                    ) {
                        appVM.navigate(to: screen)
                    }
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            // Cost ticker
            costTicker
                .padding(.bottom, 20)
        }
        .frame(width: 72)
        .background(Color.appBackground)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 1),
            alignment: .trailing
        )
    }

    private var logoView: some View {
        Image("AppLogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 40, height: 40)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .neonGlow(color: .aiClaude, radius: 16)
    }

    private var costTicker: some View {
        VStack(spacing: 4) {
            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.bottom, 8)

            Image(systemName: "dollarsign.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(.neonGreen)

            Text(String(format: "$%.2f", appVM.totalCost))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}

// MARK: - SidebarNavItem

struct SidebarNavItem: View {
    let screen: AppScreen
    let isActive: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        isActive
                            ? Color.aiClaude.opacity(0.2)
                            : (isHovered ? Color.white.opacity(0.04) : Color.clear)
                    )
                    .frame(width: 48, height: 48)

                Image(systemName: screen.systemImage)
                    .font(.system(size: 20))
                    .foregroundStyle(
                        isActive
                            ? Color.aiClaude
                            : Color.white.opacity(isHovered ? 0.8 : 0.4)
                    )

                if isActive {
                    Rectangle()
                        .fill(Color.aiClaude)
                        .frame(width: 3, height: 28)
                        .clipShape(Capsule())
                        .shadow(color: Color.aiClaude.opacity(0.8), radius: 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .offset(x: -24)
                }
            }
            .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
        .neonGlow(color: .aiClaude, radius: isActive ? 20 : 0)
        .onHover { isHovered = $0 }
        .help(screen.title)
    }
}
