import SwiftUI

struct PulsingDot: View {
    var color: Color = .aiClaude
    var size: CGFloat = 8

    @State private var pulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size * 2, height: size * 2)
                .scaleEffect(pulsing ? 1.4 : 1.0)
                .opacity(pulsing ? 0 : 0.6)

            Circle()
                .fill(color)
                .frame(width: size, height: size)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                pulsing = true
            }
        }
    }
}

// MARK: - ThinkingDots

struct ThinkingDots: View {
    var color: Color = .aiClaude

    @State private var offset1: CGFloat = 0
    @State private var offset2: CGFloat = 0
    @State private var offset3: CGFloat = 0

    var body: some View {
        HStack(spacing: 3) {
            Circle()
                .fill(color)
                .frame(width: 4, height: 4)
                .offset(y: offset1)
            Circle()
                .fill(color)
                .frame(width: 4, height: 4)
                .offset(y: offset2)
            Circle()
                .fill(color)
                .frame(width: 4, height: 4)
                .offset(y: offset3)
        }
        .onAppear {
            animateDot(delay: 0) { offset1 = $0 }
            animateDot(delay: 0.15) { offset2 = $0 }
            animateDot(delay: 0.3) { offset3 = $0 }
        }
    }

    private func animateDot(delay: Double, setter: @escaping (CGFloat) -> Void) {
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true).delay(delay)) {
            setter(-4)
        }
    }
}
