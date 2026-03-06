import SwiftUI

struct SchedulingSection: View {
    @Environment(AdminViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm
        VStack(alignment: .leading, spacing: 20) {
            // Auto-start toggle
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("AUTO-START GAMES")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.85))
                    Text("Automatically begin games at scheduled times")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
                Toggle("", isOn: $vm.settings.autoStartEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .neonViolet))
                    .labelsHidden()
            }
            .padding(14)
            .glassCard(padding: 0, cornerRadius: 10)

            if vm.settings.autoStartEnabled {
                // Time picker
                adminGroup(title: "START TIME") {
                    DatePicker("", selection: $vm.settings.autoStartTime, displayedComponents: [.hourAndMinute])
                        .datePickerStyle(.stepperField)
                        .labelsHidden()
                        .colorScheme(.dark)
                }

                // Repeat
                adminGroup(title: "REPEAT") {
                    Picker("", selection: $vm.settings.repeatSchedule) {
                        ForEach(RepeatSchedule.allCases, id: \.self) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                // Unattended mode
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            Image(systemName: "moon.fill")
                                .foregroundStyle(.neonViolet)
                            Text("UNATTENDED OVERNIGHT MODE")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        Text("Run tournaments while you sleep. Enables auto-recovery and keeps Mac awake.")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    Spacer()
                    Toggle("", isOn: $vm.settings.unattendedMode)
                        .toggleStyle(SwitchToggleStyle(tint: .neonViolet))
                        .labelsHidden()
                }
                .padding(14)
                .glassCard(padding: 0, cornerRadius: 10)

                if vm.settings.unattendedMode {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.neonAmber)
                        Text("Unattended mode will prevent your Mac from sleeping and use API budget autonomously.")
                            .font(.system(size: 10))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(10)
                    .background(Color.neonAmber.opacity(0.08))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.neonAmber.opacity(0.2), lineWidth: 1))
                }

                // Upcoming schedule preview
                adminGroup(title: "UPCOMING SCHEDULE") {
                    VStack(spacing: 8) {
                        ForEach(upcomingSchedule(), id: \.0) { item in
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundStyle(.neonCyan.opacity(0.6))
                                Text(item.0)
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.7))
                                Spacer()
                                Text(item.1)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.4))
                            }
                        }
                    }
                }
            }
        }
    }

    private func upcomingSchedule() -> [(String, String)] {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        let timeStr = fmt.string(from: vm.settings.autoStartTime)
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "EEE MMM d"
        let today = Date()
        var items: [(String, String)] = []
        for i in 0..<3 {
            let date = Calendar.current.date(byAdding: .day, value: i, to: today) ?? today
            items.append((timeStr, dateFmt.string(from: date)))
        }
        return items
    }

    private func adminGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
            content()
                .padding(14)
                .glassCard(padding: 0, cornerRadius: 10)
        }
    }
}
