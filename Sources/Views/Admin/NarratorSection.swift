import SwiftUI
import UniformTypeIdentifiers

struct NarratorSection: View {
    @Environment(AdminViewModel.self) private var vm
    private var narrator: NarratorService { NarratorService.shared }

    @State private var showSetupGuide: Bool = false
    @State private var showVoiceUpload: Bool = false
    @State private var uploadVoiceName: String = ""
    @State private var copiedSetupCommand: Bool = false

    var body: some View {
        @Bindable var vm = vm
        VStack(alignment: .leading, spacing: 20) {
            // Enable narrator
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("NARRATOR")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.85))
                    Text("AI commentary narrated with TTS")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
                Toggle("", isOn: $vm.settings.narratorEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .neonViolet))
                    .labelsHidden()
            }
            .padding(14)
            .glassCard(padding: 0, cornerRadius: 10)

            if vm.settings.narratorEnabled {
                // Provider
                adminGroup(title: "TTS PROVIDER") {
                    HStack(spacing: 12) {
                        providerButton(.elevenLabs, isSelected: vm.settings.narratorProvider == .elevenLabs) {
                            vm.settings.narratorProvider = .elevenLabs
                            vm.saveSettings()
                        }
                        providerButton(.openAI, isSelected: vm.settings.narratorProvider == .openAI) {
                            vm.settings.narratorProvider = .openAI
                            vm.saveSettings()
                        }
                        providerButton(.chatterbox, isSelected: vm.settings.narratorProvider == .chatterbox) {
                            vm.settings.narratorProvider = .chatterbox
                            vm.saveSettings()
                        }
                    }
                }

                // Voice selection / provider config
                if vm.settings.narratorProvider == .elevenLabs {
                    elevenLabsVoiceSection
                } else if vm.settings.narratorProvider == .chatterbox {
                    chatterboxConfigSection
                } else {
                    adminGroup(title: "VOICE PRESET") {
                        VStack(spacing: 8) {
                            ForEach(NarratorVoice.allCases, id: \.self) { voice in
                                voiceCard(voice.rawValue,
                                          isSelected: vm.settings.narratorVoice == voice) {
                                    vm.settings.narratorVoice = voice
                                }
                            }
                        }
                    }
                }

                // Sliders
                adminGroup(title: "AUDIO SETTINGS") {
                    VStack(spacing: 14) {
                        sliderRow(label: "Speed", value: $vm.settings.narratorSpeed, range: 0.5...2.0,
                                  displayFormat: { String(format: "%.1f×", $0) })
                        sliderRow(label: "Pitch", value: $vm.settings.narratorPitch, range: 0.5...2.0,
                                  displayFormat: { String(format: "%.1f", $0) })
                    }
                }

                // Test button
                Button {
                    Task { await vm.testNarrator() }
                } label: {
                    HStack(spacing: 8) {
                        if vm.isTestingNarrator {
                            WaveformView()
                                .frame(width: 40, height: 16)
                            Text("TESTING...")
                        } else {
                            Image(systemName: "play.circle.fill")
                            Text("TEST NARRATOR")
                        }
                    }
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundStyle(vm.isTestingNarrator ? .neonViolet : .white.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cardBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)
                .disabled(vm.isTestingNarrator)

                // Commentary AI
                commentaryAISection
            }
        }
    }

    // MARK: - Commentary AI Section

    private var commentaryAISection: some View {
        @Bindable var vm = vm
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("COMMENTARY AI")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.85))
                    Text("AI-generated snarky play-by-play narration")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                }
                Spacer()
                Toggle("", isOn: $vm.settings.commentaryAIEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: .neonCyan))
                    .labelsHidden()
            }
            .padding(14)
            .glassCard(padding: 0, cornerRadius: 10)

            if vm.settings.commentaryAIEnabled {
                adminGroup(title: "COMMENTARY FREQUENCY") {
                    VStack(spacing: 10) {
                        HStack {
                            Text("Rate")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.7))
                                .frame(width: 50, alignment: .leading)
                            Slider(value: $vm.settings.commentaryRate, in: 0.0...1.0, step: 0.05)
                                .tint(.neonCyan)
                            Text(String(format: "%.0f%%", vm.settings.commentaryRate * 100))
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundStyle(.neonCyan)
                                .frame(width: 40, alignment: .trailing)
                        }
                        Text("Controls how often the AI narrator comments. Lower = less chatter, higher = more commentary.")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }

                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.neonCyan.opacity(0.7))
                    Text("Uses a free LLM via OpenRouter. Falls back to built-in templates when AI is unavailable.")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.neonCyan.opacity(0.04))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - ElevenLabs Voice Section

    private var elevenLabsVoiceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("VOICE")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
                Button {
                    Task { await vm.fetchElevenLabsVoices() }
                } label: {
                    HStack(spacing: 4) {
                        if narrator.isFetchingVoices {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 12, height: 12)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 10))
                        }
                        Text(narrator.isFetchingVoices ? "LOADING..." : "REFRESH FROM ACCOUNT")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                    }
                    .foregroundStyle(narrator.isFetchingVoices ? .white.opacity(0.3) : .neonCyan)
                }
                .buttonStyle(.plain)
                .disabled(narrator.isFetchingVoices)
            }

            VStack(spacing: 0) {
                if let err = narrator.voiceFetchError {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.neonAmber)
                        Text(err)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.neonAmber)
                            .textSelection(.enabled)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else if narrator.availableVoices.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.badge.exclamationmark")
                            .foregroundStyle(.white.opacity(0.3))
                        Text("Tap \"Refresh from account\" to load your ElevenLabs voices")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(narrator.availableVoices) { voice in
                        let isSelected = narrator.selectedElevenLabsVoiceID == voice.voice_id
                        voiceCard(voice.name, isSelected: isSelected) {
                            narrator.selectedElevenLabsVoiceID = voice.voice_id
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                    }
                    .padding(.vertical, 6)
                }
            }
            .background(Color.cardBackground)
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardBorder, lineWidth: 1))
        }
        .task {
            if narrator.availableVoices.isEmpty {
                await vm.fetchElevenLabsVoices()
            }
        }
    }

    // MARK: - ChatterBox Config Section

    private var chatterboxConfigSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Info banner
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.neonCyan)
                Text("LOCAL TTS ENGINE — No API key required. Runs on your machine.")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.neonCyan)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.neonCyan.opacity(0.08))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.neonCyan.opacity(0.2), lineWidth: 1))

            // Open admin UI button
            Button {
                if let url = URL(string: "http://localhost:4124") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "globe")
                    Text("OPEN CHATTERBOX ADMIN")
                }
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.neonCyan)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.neonCyan.opacity(0.05))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.neonCyan.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(.plain)

            // Find more voices link
            Button {
                if let url = URL(string: "https://fish.audio/discovery/") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "music.mic.circle.fill")
                    Text("FIND MORE VOICES")
                }
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.neonAmber)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.neonAmber.opacity(0.08))
                .cornerRadius(6)
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.neonAmber.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)

            // Setup guide
            chatterboxSetupGuide

            // Server URL field
            adminGroup(title: "SERVER URL") {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        TextField("http://127.0.0.1:4123", text: Binding(
                            get: { vm.settings.chatterboxServerURL },
                            set: { vm.settings.chatterboxServerURL = $0 }
                        ))
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cardBorder, lineWidth: 1))

                        connectionStatusIcon
                    }

                    // Test connection button
                    Button {
                        Task { await vm.checkChatterboxConnection() }
                    } label: {
                        HStack(spacing: 6) {
                            if narrator.isCheckingChatterbox {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .frame(width: 12, height: 12)
                                Text("CHECKING...")
                            } else {
                                Image(systemName: "bolt.fill")
                                Text("TEST CONNECTION")
                            }
                        }
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(narrator.isCheckingChatterbox ? .white.opacity(0.3) : .neonCyan)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.03))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cardBorder, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .disabled(narrator.isCheckingChatterbox)

                    // Start Server button (when not connected)
                    if narrator.chatterboxConnectionStatus == .unreachable ||
                       narrator.chatterboxConnectionStatus == .unknown {
                        startServerButton
                    }

                    // Status message
                    if narrator.chatterboxConnectionStatus != .unknown {
                        connectionStatusMessage
                    }
                }
            }

            // Voice library (shown when connected)
            if narrator.chatterboxConnectionStatus == .connected {
                chatterboxVoiceLibrary
            }
        }
    }

    // MARK: - Setup Guide

    private var chatterboxSetupGuide: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showSetupGuide.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: showSetupGuide ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.neonCyan)
                        .frame(width: 12)
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(.neonCyan)
                    Text("HOW TO SET UP")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(.neonCyan)
                    Spacer()
                }
                .padding(10)
                .background(Color.neonCyan.opacity(0.05))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.neonCyan.opacity(0.15), lineWidth: 1))
            }
            .buttonStyle(.plain)

            if showSetupGuide {
                VStack(alignment: .leading, spacing: 12) {
                    setupStep(number: "1", title: "Install Python 3.12+", detail: "Download from python.org or use brew:\nbrew install python@3.12")
                    setupStep(number: "2", title: "Install & Start", detail: "Click the \"Install & Start ChatterBox\" button below,\nor copy the command to run manually in Terminal.")

                    // Copy setup command button
                    Button {
                        let command = "bash \"\(setupScriptPath)\""
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(command, forType: .string)
                        copiedSetupCommand = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copiedSetupCommand = false
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: copiedSetupCommand ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 10))
                            Text(copiedSetupCommand ? "COPIED!" : "COPY SETUP COMMAND")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                        }
                        .foregroundStyle(copiedSetupCommand ? .green : .neonCyan)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.neonCyan.opacity(0.08))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.neonCyan.opacity(0.2), lineWidth: 1))
                    }
                    .buttonStyle(.plain)

                    setupStep(number: "3", title: "Start the Server", detail: "bash ~/start-chatterbox.sh")
                    setupStep(number: "4", title: "Test Connection", detail: "Click \"Test Connection\" above. When the dot turns green, you're ready!")
                }
                .padding(12)
                .background(Color.cardBackground)
                .cornerRadius(0)
                .cornerRadius(8, antialiased: true)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.neonCyan.opacity(0.1), lineWidth: 1)
                        .padding(.top, 30)
                )
            }
        }
    }

    private var setupScriptPath: String {
        // Use the bundled script (ships inside the .app)
        if let bundled = Bundle.main.url(forResource: "chatterbox-setup", withExtension: "sh") {
            return bundled.path
        }
        // Fallback for Xcode builds
        let projectDir = (Bundle.main.bundlePath as NSString).deletingLastPathComponent
        return "\(projectDir)/chatterbox-setup.sh"
    }

    private func setupStep(number: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.system(size: 10, weight: .black, design: .monospaced))
                .foregroundStyle(.neonCyan)
                .frame(width: 18, height: 18)
                .background(Color.neonCyan.opacity(0.15))
                .cornerRadius(4)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.85))
                Text(detail)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.45))
                    .textSelection(.enabled)
            }
        }
    }

    // MARK: - Voice Library

    private var chatterboxVoiceLibrary: some View {
        VStack(alignment: .leading, spacing: 10) {
            voiceLibraryHeader
            voiceListContainer
            voiceUploadButton
            voiceUploadErrorView
        }
        .task {
            if narrator.chatterboxVoices.isEmpty {
                await vm.fetchChatterboxVoices()
            }
        }
    }

    private var voiceLibraryHeader: some View {
        HStack {
            Text("VOICE LIBRARY")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))
            Spacer()
            Button {
                Task { await vm.fetchChatterboxVoices() }
            } label: {
                HStack(spacing: 4) {
                    if narrator.isFetchingChatterboxVoices {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 12, height: 12)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                    }
                    Text(narrator.isFetchingChatterboxVoices ? "LOADING..." : "REFRESH")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                }
                .foregroundStyle(narrator.isFetchingChatterboxVoices ? .white.opacity(0.3) : .neonCyan)
            }
            .buttonStyle(.plain)
            .disabled(narrator.isFetchingChatterboxVoices)
        }
    }

    private var voiceListContainer: some View {
        VStack(spacing: 0) {
            if let err = narrator.chatterboxVoiceFetchError {
                voiceFetchErrorBanner(err)
            } else {
                voiceListContent
            }
        }
        .padding(.vertical, 6)
        .background(Color.cardBackground)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardBorder, lineWidth: 1))
    }

    private func voiceFetchErrorBanner(_ err: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.neonAmber)
            Text(err)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(.neonAmber)
                .textSelection(.enabled)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var voiceListContent: some View {
        VStack(spacing: 0) {
            // Default voice option (always available)
            chatterboxVoiceRow(
                name: "Default Voice",
                language: "Built-in",
                isSelected: (vm.settings.selectedChatterboxVoice ?? "default") == "default"
            ) {
                vm.settings.selectedChatterboxVoice = nil
                narrator.selectedChatterboxVoice = nil
                vm.saveSettings()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)

            // Server voices
            ForEach(narrator.chatterboxVoices) { voice in
                let isSelected = vm.settings.selectedChatterboxVoice == voice.name
                chatterboxVoiceRow(
                    name: voice.name,
                    language: voice.language,
                    isSelected: isSelected
                ) {
                    vm.settings.selectedChatterboxVoice = voice.name
                    narrator.selectedChatterboxVoice = voice.name
                    vm.saveSettings()
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
            }
        }
    }

    private var voiceUploadButton: some View {
        let uploadLabel = voiceUploadLabel
        return Button {
            showVoiceUpload = true
        } label: {
            uploadLabel
        }
        .buttonStyle(.plain)
        .disabled(narrator.isUploadingVoice)
        .fileImporter(
            isPresented: $showVoiceUpload,
            allowedContentTypes: voiceFileTypes,
            allowsMultipleSelection: false,
            onCompletion: handleVoiceFileImport
        )
    }

    private var voiceUploadLabel: some View {
        HStack(spacing: 6) {
            if narrator.isUploadingVoice {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 12, height: 12)
                Text("UPLOADING...")
            } else {
                Image(systemName: "waveform.badge.plus")
                Text("UPLOAD VOICE SAMPLE")
            }
        }
        .font(.system(size: 10, weight: .bold, design: .monospaced))
        .foregroundStyle(narrator.isUploadingVoice ? .white.opacity(0.3) : .neonViolet)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.neonViolet.opacity(0.05))
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.neonViolet.opacity(0.2), lineWidth: 1))
    }

    private var voiceFileTypes: [UTType] {
        [
            .mp3, .wav, .aiff,
            UTType(filenameExtension: "flac") ?? .audio,
            UTType(filenameExtension: "m4a") ?? .audio,
            UTType(filenameExtension: "ogg") ?? .audio
        ]
    }

    private func handleVoiceFileImport(_ result: Result<[URL], Error>) {
        if case .success(let urls) = result, let fileURL = urls.first {
            let defaultName = fileURL.deletingPathExtension().lastPathComponent
            uploadVoiceName = defaultName
            Task {
                let accessing = fileURL.startAccessingSecurityScopedResource()
                defer { if accessing { fileURL.stopAccessingSecurityScopedResource() } }
                await vm.uploadChatterboxVoice(name: uploadVoiceName, fileURL: fileURL)
            }
        }
    }

    @ViewBuilder
    private var voiceUploadErrorView: some View {
        if let err = narrator.voiceUploadError {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.neonAmber)
                Text(err)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.neonAmber)
            }
        }
    }

    private func chatterboxVoiceRow(name: String, language: String?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundStyle(isSelected ? .neonViolet : .white.opacity(0.3))
                Text(name)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(isSelected ? .neonViolet : .white.opacity(0.7))
                if let lang = language, !lang.isEmpty {
                    Text(lang.uppercased())
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundStyle(.neonCyan.opacity(0.8))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.neonCyan.opacity(0.1))
                        .cornerRadius(3)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.neonViolet)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.neonViolet.opacity(0.08) : Color.clear)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.neonViolet.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Start Server Button

    private var chatterboxIsInstalled: Bool {
        FileManager.default.fileExists(atPath: "\(NSHomeDirectory())/chatterbox-tts-api")
    }

    private var startServerButton: some View {
        VStack(spacing: 6) {
            Button {
                Task { await vm.startChatterboxServer() }
            } label: {
                HStack(spacing: 8) {
                    if vm.isLaunchingChatterbox {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 14, height: 14)
                        Text("STARTING SERVER...")
                    } else {
                        Image(systemName: chatterboxIsInstalled ? "power" : "arrow.down.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text(chatterboxIsInstalled ? "START CHATTERBOX SERVER" : "INSTALL & START CHATTERBOX")
                    }
                }
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundStyle(vm.isLaunchingChatterbox ? .white.opacity(0.4) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(vm.isLaunchingChatterbox ? Color.green.opacity(0.1) : Color.green.opacity(0.15))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.3), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(vm.isLaunchingChatterbox)

            if vm.isLaunchingChatterbox {
                Text("Installing dependencies & loading model — this may take a minute on first run.")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.35))
                    .multilineTextAlignment(.center)
            }

            if let err = vm.chatterboxLaunchError {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.neonAmber)
                    Text(err)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.neonAmber)
                }
            }
        }
    }

    @ViewBuilder
    private var connectionStatusIcon: some View {
        switch narrator.chatterboxConnectionStatus {
        case .connected:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .unreachable:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.neonAmber)
        case .unknown:
            Image(systemName: "questionmark.circle")
                .foregroundStyle(.white.opacity(0.3))
        }
    }

    @ViewBuilder
    private var connectionStatusMessage: some View {
        switch narrator.chatterboxConnectionStatus {
        case .connected:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("Server connected and ready")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.green)
            }
        case .unreachable:
            HStack(spacing: 6) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                Text("Server unreachable — is chatterbox-tts-api running?")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.red)
            }
        case .error:
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.neonAmber)
                    Text("Server error — model not loaded")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.neonAmber)
                }
                if let detail = narrator.chatterboxStatusDetail {
                    Text(detail)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundStyle(.neonAmber.opacity(0.7))
                        .textSelection(.enabled)
                        .lineLimit(3)
                }
            }
        case .unknown:
            EmptyView()
        }
    }

    // MARK: - Subviews

    private func providerIcon(_ provider: NarratorProvider) -> String {
        switch provider {
        case .elevenLabs: return "waveform.badge.mic"
        case .openAI:     return "mic.fill"
        case .chatterbox: return "desktopcomputer"
        }
    }

    private func providerButton(_ provider: NarratorProvider, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: providerIcon(provider))
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? .neonViolet : .white.opacity(0.4))
                Text(provider.rawValue)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(isSelected ? .neonViolet : .white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? Color.neonViolet.opacity(0.1) : Color.white.opacity(0.03))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.neonViolet.opacity(0.4) : Color.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func voiceCard(_ name: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundStyle(isSelected ? .neonViolet : .white.opacity(0.3))
                Text(name)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundStyle(isSelected ? .neonViolet : .white.opacity(0.7))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.neonViolet)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.neonViolet.opacity(0.08) : Color.clear)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.neonViolet.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func sliderRow(label: String, value: Binding<Double>, range: ClosedRange<Double>, displayFormat: (Double) -> String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 50, alignment: .leading)
            Slider(value: value, in: range, step: 0.1)
                .tint(.neonViolet)
            Text(displayFormat(value.wrappedValue))
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundStyle(.neonViolet)
                .frame(width: 40, alignment: .trailing)
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
