import SwiftUI
import AppKit
import QuartzCore

// MARK: - ConfettiView (NSViewRepresentable)

struct ConfettiView: NSViewRepresentable {
    func makeNSView(context: Context) -> ConfettiNSView {
        let view = ConfettiNSView()
        return view
    }

    func updateNSView(_ nsView: ConfettiNSView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator {}
}

// MARK: - ConfettiNSView

class ConfettiNSView: NSView {
    private var emitterLayer: CAEmitterLayer?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        if window != nil {
            setupEmitter()
        }
    }

    private func setupEmitter() {
        let emitter = CAEmitterLayer()
        emitter.emitterShape = .line
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.maxY + 20)
        emitter.emitterSize = CGSize(width: bounds.width, height: 0)
        emitter.renderMode = .additive

        emitter.emitterCells = [
            makeCell(color: NSColor(Color.aiClaude), shape: .circle, birthRate: 60),
            makeCell(color: NSColor(Color.aiGemini), shape: .rectangle, birthRate: 50),
            makeCell(color: NSColor(Color.neonAmber), shape: .triangle, birthRate: 40),
            makeCell(color: NSColor(Color.aiGPT4), shape: .circle, birthRate: 50),
            makeCell(color: NSColor(Color.aiMistral), shape: .rectangle, birthRate: 40),
        ]

        wantsLayer = true
        layer?.addSublayer(emitter)
        self.emitterLayer = emitter

        // Stop after 4 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak emitter] in
            emitter?.birthRate = 0
        }
    }

    private enum ParticleShape { case circle, rectangle, triangle }

    private func makeCell(color: NSColor, shape: ParticleShape, birthRate: Float) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = birthRate
        cell.lifetime = 4.0
        cell.lifetimeRange = 1.5
        cell.velocity = 200
        cell.velocityRange = 80
        cell.emissionRange = .pi / 4
        cell.emissionLongitude = .pi / 2
        cell.yAcceleration = -150
        cell.xAcceleration = CGFloat.random(in: -30...30)
        cell.spin = 3
        cell.spinRange = 6
        cell.scale = 0.06
        cell.scaleRange = 0.03
        cell.alphaRange = 0.5
        cell.alphaSpeed = -0.2
        cell.color = color.cgColor
        cell.contents = particleImage(shape: shape, color: color)
        return cell
    }

    private func particleImage(shape: ParticleShape, color: NSColor) -> CGImage? {
        let size = CGSize(width: 12, height: 12)
        let renderer = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )
        guard let rep = renderer else { return nil }
        let ctx = NSGraphicsContext(bitmapImageRep: rep)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = ctx
        color.setFill()
        switch shape {
        case .circle:
            NSBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
        case .rectangle:
            NSBezierPath(rect: CGRect(x: 1, y: 3, width: 10, height: 6)).fill()
        case .triangle:
            let path = NSBezierPath()
            path.move(to: CGPoint(x: 6, y: 11))
            path.line(to: CGPoint(x: 0, y: 1))
            path.line(to: CGPoint(x: 12, y: 1))
            path.close()
            path.fill()
        }
        NSGraphicsContext.restoreGraphicsState()
        return rep.cgImage
    }
}
