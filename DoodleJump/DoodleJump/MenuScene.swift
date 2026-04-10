import SpriteKit

class MenuScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.53, green: 0.81, blue: 0.98, alpha: 1.0)
        setupUI()
        animateBackground()
    }

    private func setupUI() {
        // Title
        let title = SKLabelNode(fontNamed: "AvenirNext-HeavyItalic")
        title.text = "DOODLE JUMP"
        title.fontSize = 42
        title.fontColor = .white
        title.position = CGPoint(x: size.width/2, y: size.height * 0.72)
        title.zPosition = 10
        addChild(title)

        let titleShadow = SKLabelNode(fontNamed: "AvenirNext-HeavyItalic")
        titleShadow.text = "DOODLE JUMP"
        titleShadow.fontSize = 42
        titleShadow.fontColor = SKColor(white: 0, alpha: 0.25)
        titleShadow.position = CGPoint(x: size.width/2 + 3, y: size.height * 0.72 - 3)
        titleShadow.zPosition = 9
        addChild(titleShadow)

        // Subtitle
        let sub = SKLabelNode(fontNamed: "AvenirNext-Medium")
        sub.text = "Jump as high as you can!"
        sub.fontSize = 18
        sub.fontColor = SKColor(white: 1, alpha: 0.85)
        sub.position = CGPoint(x: size.width/2, y: size.height * 0.64)
        addChild(sub)

        // Doodler preview
        let doodler = SKSpriteNode(color: .green, size: CGSize(width: 70, height: 70))
        doodler.position = CGPoint(x: size.width/2, y: size.height * 0.50)
        doodler.texture = makeCharTexture()
        doodler.zPosition = 5
        addChild(doodler)

        let bounce = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 15, duration: 0.4),
            SKAction.moveBy(x: 0, y: -15, duration: 0.4)
        ])
        doodler.run(SKAction.repeatForever(bounce))

        // Platform under character
        let platform = SKSpriteNode(color: SKColor(red: 0.2, green: 0.75, blue: 0.3, alpha: 1),
                                    size: CGSize(width: 100, height: 16))
        platform.position = CGPoint(x: size.width/2, y: size.height * 0.43)
        platform.zPosition = 4
        addChild(platform)

        // Play button
        addPlayButton()

        // Instructions
        let instr = SKLabelNode(fontNamed: "AvenirNext-Regular")
        instr.text = "Tilt device to move • Land on platforms"
        instr.fontSize = 14
        instr.fontColor = SKColor(white: 1, alpha: 0.7)
        instr.position = CGPoint(x: size.width/2, y: size.height * 0.15)
        addChild(instr)

        // Best score
        let best = UserDefaults.standard.integer(forKey: "bestScore")
        if best > 0 {
            let bestLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
            bestLabel.text = "Best: \(best)"
            bestLabel.fontSize = 20
            bestLabel.fontColor = SKColor(red: 1.0, green: 0.9, blue: 0.2, alpha: 1)
            bestLabel.position = CGPoint(x: size.width/2, y: size.height * 0.20)
            addChild(bestLabel)
        }
    }

    private func addPlayButton() {
        let button = SKShapeNode(rectOf: CGSize(width: 160, height: 54), cornerRadius: 27)
        button.fillColor = SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1)
        button.strokeColor = .white
        button.lineWidth = 2
        button.position = CGPoint(x: size.width/2, y: size.height * 0.29)
        button.zPosition = 10
        button.name = "playButton"
        addChild(button)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = "PLAY"
        label.fontSize = 26
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.name = "playButton"
        button.addChild(label)

        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.05, duration: 0.7),
            SKAction.scale(to: 1.0, duration: 0.7)
        ])
        button.run(SKAction.repeatForever(pulse))
    }

    private func makeCharTexture() -> SKTexture {
        let size = CGSize(width: 70, height: 70)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1).setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 14).fill()
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(x: 14, y: 18, width: 16, height: 16)).fill()
            UIBezierPath(ovalIn: CGRect(x: 38, y: 18, width: 16, height: 16)).fill()
            UIColor.black.setFill()
            UIBezierPath(ovalIn: CGRect(x: 19, y: 23, width: 7, height: 7)).fill()
            UIBezierPath(ovalIn: CGRect(x: 43, y: 23, width: 7, height: 7)).fill()
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(x: 22, y: 44, width: 24, height: 12)).fill()
        }
        return SKTexture(image: img)
    }

    private func animateBackground() {
        // Floating decorative platforms
        for i in 0..<5 {
            let plat = SKSpriteNode(color: SKColor(white: 1, alpha: 0.15),
                                   size: CGSize(width: CGFloat.random(in: 60...100), height: 12))
            plat.position = CGPoint(x: CGFloat.random(in: 0...size.width),
                                    y: CGFloat.random(in: 0...size.height))
            plat.zPosition = 1
            addChild(plat)

            let drift = SKAction.sequence([
                SKAction.moveBy(x: CGFloat.random(in: -40...40), y: 20, duration: Double.random(in: 2...4)),
                SKAction.moveBy(x: CGFloat.random(in: -40...40), y: -20, duration: Double.random(in: 2...4))
            ])
            plat.run(SKAction.repeatForever(drift))
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let nodes = self.nodes(at: loc)

        if nodes.contains(where: { $0.name == "playButton" }) {
            startGame()
        }
    }

    private func startGame() {
        let scene = GameScene(size: size)
        scene.scaleMode = .aspectFill
        view?.presentScene(scene, transition: SKTransition.doorway(withDuration: 0.6))
    }
}
