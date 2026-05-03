import SwiftUI
import SpriteKit
import UIKit

/// Confetti burst overlay. Increment `trigger` to fire a new shower.
/// Honors Reduce Motion by emitting a single static burst instead of an
/// animated stream.
struct ConfettiView: View {
    let trigger: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            SpriteView(scene: makeScene(size: proxy.size),
                       options: [.allowsTransparency])
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .onChange(of: trigger) { _, _ in fire(in: proxy.size) }
        }
    }

    @State private var sceneRef = ConfettiScene(size: .zero)

    private func makeScene(size: CGSize) -> ConfettiScene {
        if sceneRef.size != size {
            sceneRef = ConfettiScene(size: size)
            sceneRef.scaleMode = .resizeFill
            sceneRef.backgroundColor = .clear
        }
        return sceneRef
    }

    private func fire(in size: CGSize) {
        sceneRef.fireBurst(reduceMotion: reduceMotion)
    }
}

final class ConfettiScene: SKScene {
    override init(size: CGSize) {
        super.init(size: size)
        backgroundColor = .clear
        scaleMode = .resizeFill
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    func fireBurst(reduceMotion: Bool) {
        guard size.width > 0, size.height > 0 else { return }
        let count = reduceMotion ? 30 : 200
        for _ in 0..<count {
            let piece = SKShapeNode(rectOf: CGSize(width: 8, height: 14),
                                    cornerRadius: 2)
            piece.fillColor = ConfettiPalette.random()
            piece.strokeColor = .clear
            piece.position = CGPoint(x: CGFloat.random(in: 0...size.width),
                                     y: size.height + 20)
            piece.zRotation = CGFloat.random(in: 0...(.pi * 2))
            addChild(piece)
            let dx = CGFloat.random(in: -80...80)
            let dy = -CGFloat.random(in: size.height * 0.6...size.height * 1.2)
            let duration = reduceMotion
                ? 0.4
                : Double.random(in: 1.6...2.6)
            let move = SKAction.moveBy(x: dx, y: dy, duration: duration)
            let rotate = SKAction.rotate(byAngle: CGFloat.random(in: -.pi * 4...(.pi * 4)),
                                         duration: duration)
            let fade = SKAction.fadeOut(withDuration: duration * 0.3)
            let group = SKAction.group([move, rotate])
            let sequence = SKAction.sequence([group, fade,
                                              SKAction.removeFromParent()])
            piece.run(sequence)
        }
    }
}

private enum ConfettiPalette {
    static let colors: [UIColor] = [
        UIColor(red: 1.00, green: 0.62, blue: 0.32, alpha: 1),
        UIColor(red: 0.95, green: 0.30, blue: 0.55, alpha: 1),
        UIColor(red: 0.45, green: 0.10, blue: 0.65, alpha: 1),
        UIColor(red: 0.30, green: 0.85, blue: 0.55, alpha: 1),
        UIColor(red: 1.00, green: 0.92, blue: 0.40, alpha: 1),
        UIColor.white,
    ]
    static func random() -> UIColor { colors.randomElement()! }
}
