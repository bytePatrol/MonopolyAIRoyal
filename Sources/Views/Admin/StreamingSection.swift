import SwiftUI

struct StreamingSection: View {
    @Environment(AdminViewModel.self) private var vm

    var body: some View {
        @Bindable var vm = vm
        VStack(alignment: .leading, spacing: 20) {
            // Platform selector
            adminGroup(title: "PLATFORM") {
                HStack(spacing: 10) {
                    ForEach(StreamPlatform.allCases, id: \.self) { platform in
                        platformButton(platform, isSelected: vm.settings.streamPlatform == platform) {
                            vm.settings.streamPlatform = platform
                        }
                    }
                }
            }

            // RTMP Config
            adminGroup(title: "RTMP CONFIGURATION") {
                VStack(spacing: 12) {
                    adminTextField("RTMP URL", placeholder: "rtmp://live.youtube.com/live2/...",
                                   text: $vm.settings.rtmpURL)
                    adminSecureField("Stream Key", placeholder: "xxxx-xxxx-xxxx-xxxx",
                                    text: $vm.settings.rtmpKey)
                }
            }

            // Video settings
            adminGroup(title: "VIDEO QUALITY") {
                VStack(spacing: 12) {
                    HStack {
                        Text("Resolution")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Picker("", selection: $vm.settings.resolutionWidth) {
                            Text("1280×720").tag(1280)
                            Text("1920×1080").tag(1920)
                            Text("2560×1440").tag(2560)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }

                    HStack {
                        Text("Bitrate")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Text("\(vm.settings.videoBitrate / 1000) Mbps")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundStyle(.neonCyan)
                        Slider(value: Binding(
                            get: { Double(vm.settings.videoBitrate) },
                            set: { vm.settings.videoBitrate = Int($0) }
                        ), in: 1000...12000, step: 500)
                        .tint(.neonCyan)
                        .frame(width: 120)
                    }

                    HStack {
                        Text("Codec")
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.7))
                        Spacer()
                        Picker("", selection: $vm.settings.videoCodec) {
                            ForEach(VideoCodec.allCases, id: \.self) { codec in
                                Text(codec.rawValue).tag(codec)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }
                }
            }

            // Stream control
            if vm.streamingService.isStreaming {
                streamingActivePanel
            } else {
                Button {
                    Task { await vm.toggleStream() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "video.fill")
                        Text("START STREAMING")
                    }
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(LinearGradient(colors: [.neonRed.opacity(0.8), .neonPink.opacity(0.8)], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)
                .neonGlow(color: .neonRed, radius: 12)
            }
        }
    }

    private var streamingActivePanel: some View {
        VStack(spacing: 12) {
            HStack {
                PulsingDot(color: .neonRed, size: 6)
                Text("🔴 LIVE ON \(vm.streamingService.platform.rawValue.uppercased())")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundStyle(.neonRed)
                Spacer()
                Text(vm.streamingService.formattedDuration)
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.6))
            }

            HStack(spacing: 20) {
                streamStat(label: "VIEWERS", value: vm.streamingService.formattedViewers)
                streamStat(label: "BITRATE", value: vm.streamingService.formattedBitrate)
                streamStat(label: "STATUS", value: "OK")
            }

            Button {
                vm.streamingService.stopStream()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "stop.fill")
                    Text("STOP STREAM")
                }
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.neonRed)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.neonRed.opacity(0.1))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.neonRed.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .glassCard(padding: 0, cornerRadius: 10)
    }

    private func streamStat(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.3))
            Text(value)
                .font(.system(size: 14, weight: .black, design: .monospaced))
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(maxWidth: .infinity)
    }

    private func platformButton(_ platform: StreamPlatform, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(platform.rawValue)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(isSelected ? .white : .white.opacity(0.4))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.neonRed.opacity(0.25) : Color.white.opacity(0.04))
                .cornerRadius(7)
                .overlay(
                    RoundedRectangle(cornerRadius: 7)
                        .stroke(isSelected ? Color.neonRed.opacity(0.5) : Color.cardBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func adminTextField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
            TextField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .padding(8)
                .background(Color.white.opacity(0.04))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cardBorder, lineWidth: 1))
        }
    }

    private func adminSecureField(_ label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.35))
            SecureField(placeholder, text: text)
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .padding(8)
                .background(Color.white.opacity(0.04))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cardBorder, lineWidth: 1))
        }
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
