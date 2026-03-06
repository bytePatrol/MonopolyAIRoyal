import SwiftUI

struct HighlightReelSection: View {
    @State private var isDownloading = false
    @State private var isUploading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text("HIGHLIGHT REEL")
                    .font(.system(size: 16, weight: .black, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                Text("AUTO-GENERATED FROM KEY MOMENTS")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.3))
            }

            // Video player mockup
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.5))
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )

                // Fake video content
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 64, height: 64)
                        Image(systemName: "play.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Text("HIGHLIGHT REEL READY")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.5))

                    Text("3:42 · 5 key moments · HD 1080p")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.3))
                }

                // Progress bar at bottom
                VStack {
                    Spacer()
                    VStack(spacing: 4) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.white.opacity(0.1))
                                    .frame(height: 3)
                                Rectangle()
                                    .fill(LinearGradient.violetToCyan)
                                    .frame(width: geo.size.width * 0.42, height: 3)
                            }
                            .cornerRadius(2)
                        }
                        .frame(height: 3)

                        HStack {
                            Text("1:34")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.4))
                            Spacer()
                            Text("3:42")
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.4))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                actionButton(
                    label: isDownloading ? "Downloading..." : "Download MP4",
                    icon: "arrow.down.circle.fill",
                    color: .neonCyan
                ) {
                    isDownloading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { isDownloading = false }
                }

                actionButton(
                    label: "Share",
                    icon: "square.and.arrow.up",
                    color: .neonViolet
                ) {}

                actionButton(
                    label: isUploading ? "Uploading..." : "Upload to YouTube",
                    icon: "arrow.up.circle.fill",
                    color: .neonRed
                ) {
                    isUploading = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) { isUploading = false }
                }
            }
        }
    }

    private func actionButton(label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(label)
            }
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(color.opacity(0.08))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
