import SwiftUI

struct TrashTalkPanel: View {
    @Environment(LobbyViewModel.self) private var vm

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    PulsingDot(color: .neonGreen, size: 5)
                    Text("PRE-GAME BANTER")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
                Text("\(vm.trashTalkMessages.count) messages")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.cardBackground)
            .overlay(Rectangle().fill(Color.cardBorder).frame(height: 1), alignment: .bottom)

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(vm.trashTalkMessages) { msg in
                            TrashTalkBubble(message: msg)
                                .id(msg.id)
                        }

                        // Typing indicator
                        if vm.isGeneratingTrashTalk {
                            TypingIndicator()
                        }
                    }
                    .padding(12)
                }
                .onChange(of: vm.trashTalkMessages.count) { _, _ in
                    if let last = vm.trashTalkMessages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .background(Color.appBackground)
        }
        .background(Color.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
    }
}

// MARK: - Trash Talk Bubble

struct TrashTalkBubble: View {
    let message: TrashTalkMessage

    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: message.colorHex))
                    .frame(width: 8, height: 8)
                Text(message.playerName)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(hex: message.colorHex))
                Spacer()
                Text(timeString(from: message.timestamp))
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.25))
            }

            Text(message.message)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.8))
                .lineSpacing(2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: message.colorHex).opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(hex: message.colorHex).opacity(0.15), lineWidth: 1)
                )
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.05)) {
                appeared = true
            }
        }
    }

    private func timeString(from date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm"
        return fmt.string(from: date)
    }
}

// MARK: - Typing Indicator

struct TypingIndicator: View {
    var body: some View {
        HStack(spacing: 6) {
            ThinkingDots(color: .white.opacity(0.4))
            Text("AI generating responses...")
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.03))
        .cornerRadius(6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
