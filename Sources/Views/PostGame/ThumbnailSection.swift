import SwiftUI

struct ThumbnailSection: View {
    @State var title: String
    let subtitle: String
    @State private var isCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("VIDEO THUMBNAIL")
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                Text("EDITABLE TITLE OVERLAY")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }

            HStack(spacing: 20) {
                // 16:9 thumbnail preview
                thumbnailPreview
                    .frame(maxWidth: .infinity)

                // Controls
                VStack(alignment: .leading, spacing: 14) {
                    // Title input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("TITLE")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.35))
                        TextField("Thumbnail title...", text: $title)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cardBorder))
                    }

                    Text(subtitle)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.4))

                    Spacer()

                    // Buttons
                    VStack(spacing: 8) {
                        Button {
                            isCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { isCopied = false }
                        } label: {
                            HStack {
                                Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                Text(isCopied ? "COPIED!" : "COPY TO CLIPBOARD")
                            }
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(isCopied ? .neonGreen : .white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(7)
                        }
                        .buttonStyle(.plain)

                        Button {} label: {
                            HStack {
                                Image(systemName: "arrow.down.circle")
                                Text("DOWNLOAD PNG")
                            }
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.neonCyan)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.neonCyan.opacity(0.08))
                            .cornerRadius(7)
                            .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.neonCyan.opacity(0.25), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(width: 220)
            }
        }
    }

    private var thumbnailPreview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.appBackground, Color(hex: "#120520")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .aspectRatio(16/9, contentMode: .fit)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.aiClaude.opacity(0.2), lineWidth: 1)
                )

            // Background glow elements
            Circle()
                .fill(Color.aiClaude.opacity(0.15))
                .frame(width: 200, height: 200)
                .blur(radius: 60)
                .offset(x: -60, y: -30)

            Circle()
                .fill(Color.aiGemini.opacity(0.1))
                .frame(width: 150, height: 150)
                .blur(radius: 50)
                .offset(x: 80, y: 40)

            // Content
            VStack(spacing: 8) {
                Text("🏆")
                    .font(.system(size: 32))

                Text(title)
                    .font(.system(size: 18, weight: .black, design: .monospaced))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.aiClaude.opacity(0.6), radius: 8)

                Text("MONOPOLY AI ROYAL · V7")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                    .tracking(4)
            }
            .padding()
        }
    }
}
