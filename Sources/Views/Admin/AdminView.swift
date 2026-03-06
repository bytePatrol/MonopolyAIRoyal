import SwiftUI

struct AdminView: View {
    @Environment(AdminViewModel.self) private var vm

    var body: some View {
        HSplitView {
            // Left sidebar
            adminSidebar
                .frame(minWidth: 160, maxWidth: 180)

            // Right content
            adminContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.appBackground)
    }

    // MARK: - Sidebar

    private var adminSidebar: some View {
        @Bindable var vm = vm
        return VStack(spacing: 0) {
            // Header
            HStack {
                Text("ADMIN")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.cardBackground)
            .overlay(Rectangle().fill(Color.cardBorder).frame(height: 1), alignment: .bottom)

            // Nav items
            ScrollView {
                VStack(spacing: 2) {
                    ForEach(AdminSection.allCases, id: \.self) { section in
                        AdminNavItem(
                            section: section,
                            isSelected: vm.selectedSection == section
                        ) {
                            vm.selectedSection = section
                        }
                    }
                }
                .padding(8)
            }

            Spacer()

            // Save button
            Button {
                vm.saveSettings()
                vm.saveKeys()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("SAVE ALL")
                }
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(.neonGreen)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.neonGreen.opacity(0.1))
                .overlay(Rectangle().fill(Color.cardBorder).frame(height: 1), alignment: .top)
            }
            .buttonStyle(.plain)
        }
        .background(Color.cardBackground)
    }

    // MARK: - Content

    @ViewBuilder
    private var adminContent: some View {
        @Bindable var vm = vm
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Section header
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: vm.selectedSection.systemImage)
                            .font(.system(size: 16))
                            .foregroundStyle(.neonViolet)
                        Text(vm.selectedSection.rawValue.uppercased())
                            .font(.system(size: 16, weight: .black, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .background(Color.cardBackground)
                .overlay(Rectangle().fill(Color.cardBorder).frame(height: 1), alignment: .bottom)

                // Section content
                sectionContent
                    .padding(24)
            }
        }
        .background(Color.appBackground)
    }

    @ViewBuilder
    private var sectionContent: some View {
        @Bindable var vm = vm
        switch vm.selectedSection {
        case .models:     ModelsSection().environment(vm)
        case .rules:      RulesSection().environment(vm)
        case .tournament: TournamentSection().environment(vm)
        case .streaming:  StreamingSection().environment(vm)
        case .narrator:   NarratorSection().environment(vm)
        case .budget:     BudgetSection().environment(vm)
        case .apiKeys:    APIKeysSection().environment(vm)
        case .scheduling: SchedulingSection().environment(vm)
        }
    }
}

// MARK: - Admin Nav Item

struct AdminNavItem: View {
    let section: AdminSection
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 13))
                    .foregroundStyle(isSelected ? .neonViolet : .white.opacity(0.45))
                    .frame(width: 20)

                Text(section.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(isSelected ? .neonViolet : .white.opacity(0.5))

                Spacer()

                if isSelected {
                    Rectangle()
                        .fill(Color.neonViolet)
                        .frame(width: 2, height: 16)
                        .cornerRadius(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? Color.neonViolet.opacity(0.1)
                    : (isHovered ? Color.white.opacity(0.03) : Color.clear)
            )
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
