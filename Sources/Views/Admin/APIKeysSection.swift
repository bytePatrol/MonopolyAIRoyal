import SwiftUI

struct APIKeysSection: View {
    @Environment(AdminViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm
        VStack(alignment: .leading, spacing: 20) {
            // Info banner
            HStack(spacing: 10) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(.neonGreen)
                    .font(.system(size: 20))
                VStack(alignment: .leading, spacing: 2) {
                    Text("KEYCHAIN SECURED")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.neonGreen)
                    Text("API keys are stored in macOS Keychain — never in plain text")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(12)
            .background(Color.neonGreen.opacity(0.06))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.neonGreen.opacity(0.2), lineWidth: 1))

            // OpenRouter keys
            adminGroup(title: "OPENROUTER KEYS") {
                VStack(spacing: 12) {
                    keyField("Primary Key", placeholder: "sk-or-...", text: $vm.openRouterPrimaryKey, status: vm.openRouterKeyStatus)
                    keyField("Fallback Key 1", placeholder: "sk-or-...", text: $vm.openRouterFallback1Key, status: .unknown)
                    keyField("Fallback Key 2", placeholder: "sk-or-...", text: $vm.openRouterFallback2Key, status: .unknown)
                    keyField("Fallback Key 3", placeholder: "sk-or-...", text: $vm.openRouterFallback3Key, status: .unknown)

                    HStack(spacing: 10) {
                        Button {
                            Task { await vm.validateOpenRouterKey() }
                        } label: {
                            HStack(spacing: 5) {
                                if vm.openRouterKeyStatus == .checking {
                                    ProgressView().scaleEffect(0.6).tint(.white)
                                } else {
                                    Image(systemName: "checkmark.shield")
                                }
                                Text("VALIDATE KEY")
                            }
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.neonCyan)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.neonCyan.opacity(0.1))
                            .cornerRadius(7)
                        }
                        .buttonStyle(.plain)
                        .disabled(vm.openRouterKeyStatus == .checking)

                        Button {
                            vm.saveKeys()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: "tray.and.arrow.down.fill")
                                Text("SAVE TO KEYCHAIN")
                            }
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.neonGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.neonGreen.opacity(0.1))
                            .cornerRadius(7)
                        }
                        .buttonStyle(.plain)
                    }

                    // Validation status
                    if vm.openRouterKeyStatus != .unknown {
                        keyStatusBanner(vm.openRouterKeyStatus)
                    }
                }
            }

            // ElevenLabs key
            adminGroup(title: "ELEVENLABS KEY") {
                VStack(spacing: 12) {
                    keyField("ElevenLabs API Key", placeholder: "xi-...", text: $vm.elevenLabsKey, status: vm.elevenLabsKeyStatus)

                    Button {
                        if !vm.elevenLabsKey.isEmpty {
                            KeychainService.store(key: vm.elevenLabsKey, account: .elevenLabs)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "tray.and.arrow.down.fill")
                            Text("SAVE ELEVENLABS KEY")
                        }
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundStyle(.neonGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.neonGreen.opacity(0.1))
                        .cornerRadius(7)
                    }
                    .buttonStyle(.plain)
                    .disabled(vm.elevenLabsKey.isEmpty)
                }
            }
        }
    }

    private func keyField(_ label: String, placeholder: String, text: Binding<String>, status: AdminViewModel.KeyStatus) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
            HStack {
                SecureField(placeholder, text: text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                Spacer()
                if status == .valid {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.neonGreen)
                } else if status == .invalid {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.neonRed)
                }
            }
            .padding(8)
            .background(Color.white.opacity(0.04))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        status == .valid ? Color.neonGreen.opacity(0.4) :
                        status == .invalid ? Color.neonRed.opacity(0.4) :
                        Color.cardBorder,
                        lineWidth: 1
                    )
            )
        }
    }

    private func keyStatusBanner(_ status: AdminViewModel.KeyStatus) -> some View {
        HStack(spacing: 8) {
            Image(systemName: status == .valid ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(status == .valid ? .neonGreen : .neonRed)
            Text(status == .valid ? "API key is valid — OpenRouter connection established" : "Invalid key — check and try again")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(status == .valid ? .neonGreen.opacity(0.8) : .neonRed.opacity(0.8))
        }
        .padding(8)
        .background(status == .valid ? Color.neonGreen.opacity(0.08) : Color.neonRed.opacity(0.08))
        .cornerRadius(6)
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
