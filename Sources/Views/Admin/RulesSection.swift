import SwiftUI

struct RulesSection: View {
    @Environment(AdminViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm
        VStack(alignment: .leading, spacing: 20) {
            // Numeric settings
            adminGroup(title: "GAME PARAMETERS") {
                VStack(spacing: 12) {
                    numericField("Starting Cash", value: $vm.settings.startingCash, range: 500...5000, step: 100)
                    numericField("GO Salary", value: $vm.settings.goSalary, range: 0...500, step: 50)
                    numericField("Jail Bail", value: $vm.settings.jailBail, range: 10...200, step: 10)
                    numericField("Max Turns", value: $vm.settings.maxTurns, range: 50...999, step: 10)
                }
            }

            // Win condition
            adminGroup(title: "WIN CONDITION") {
                Picker("Win Condition", selection: $vm.settings.winCondition) {
                    ForEach(WinCondition.allCases, id: \.self) { wc in
                        Text(wc.rawValue).tag(wc)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            // House rules
            adminGroup(title: "HOUSE RULES") {
                VStack(spacing: 10) {
                    ruleToggle("Free Parking Jackpot", isOn: $vm.settings.freeParkingJackpot,
                               description: "Taxes go to Free Parking pot")
                    ruleToggle("Auction Unowned Properties", isOn: $vm.settings.auctionUnboughtProperties,
                               description: "If AI passes on buying, auction it")
                    ruleToggle("No Rent in Jail", isOn: $vm.settings.noRentInJail,
                               description: "Jailed players don't collect rent")
                    ruleToggle("Roll Doubles to Exit Jail", isOn: $vm.settings.doublesGetOutOfJail,
                               description: "Can roll doubles 3× before paying bail")
                }
            }
        }
    }

    private func adminGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
            content()
                .padding(14)
                .glassCard(padding: 0, cornerRadius: 10)
        }
    }

    private func numericField(_ label: String, value: Binding<Int>, range: ClosedRange<Int>, step: Int) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
            Spacer()
            Stepper(value: value, in: range, step: step) {
                Text("$\(value.wrappedValue)")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.neonViolet)
                    .frame(width: 70, alignment: .trailing)
            }
        }
    }

    private func ruleToggle(_ label: String, isOn: Binding<Bool>, description: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.8))
                Text(description)
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.35))
            }
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle(tint: .neonViolet))
                .labelsHidden()
        }
    }
}
