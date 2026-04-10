import SpriteKit

class GameOverScene: SKScene {

    private let finalScore: Int

    init(size: CGSize, score: Int) {
        self.finalScore = score
        super.init(size: size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.15, green: 0.15, blue: 0.25, alpha: 1.0)
        saveBestScore()
        setupUI()
    }

    private func saveBestScore() {
        let best = UserDefaults.standard.integer(forKey: "bestScore")
        if finalScore > best {
            UserDefaults.standard.set(finalScore, forKey: "bestScore")
        }
    }

    private func setupUI() {
        // Game Over title
        let gameOver = SKLabelNode(fontNamed: "AvenirNext-HeavyItalic")
        gameOver.text = "GAME OVER"
        gameOver.fontSize = 44
        gameOver.fontColor = SKColor(red: 1, green: 0.35, blue: 0.35, alpha: 1)
        gameOver.position = CGPoint(x: size.width/2, y: size.height * 0.75)
        gameOver.zPosition = 10
        addChild(gameOver)

        let shake = SKAction.sequence([
            SKAction.moveBy(x: -5, y: 0, duration: 0.05),
            SKAction.moveBy(x: 10, y: 0, duration: 0.05),
            SKAction.moveBy(x: -5, y: 0, duration: 0.05)
        ])
        gameOver.run(SKAction.repeat(shake, count: 3))

        // Score card background
        let card = SKShapeNode(rectOf: CGSize(width: 260, height: 160), cornerRadius: 20)
        card.fillColor = SKColor(white: 1, alpha: 0.1)
        card.strokeColor = SKColor(white: 1, alpha: 0.2)
        card.lineWidth = 1.5
        card.position = CGPoint(x: size.width/2, y: size.height * 0.56)
        addChild(card)

        // Score
        let scoreTitle = SKLabelNode(fontNamed: "AvenirNext-Medium")
        scoreTitle.text = "YOUR SCORE"
        scoreTitle.fontSize = 14
        scoreTitle.fontColor = SKColor(white: 1, alpha: 0.6)
        scoreTitle.position = CGPoint(x: 0, y: 45)
        card.addChild(scoreTitle)

        let scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.text = "\(finalScore)"
        scoreLabel.fontSize = 52
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: 0, y: -10)
        card.addChild(scoreLabel)

        // Best score
        let best = UserDefaults.standard.integer(forKey: "bestScore")
        let bestLabel = SKLabelNode(fontNamed: "AvenirNext-Medium")
        bestLabel.text = "Best: \(best)"
        bestLabel.fontSize = 16
        bestLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1)
        bestLabel.position = CGPoint(x: 0, y: -55)
        card.addChild(bestLabel)

        if finalScore >= best {
            let newBest = SKLabelNode(fontNamed: "AvenirNext-HeavyItalic")
            newBest.text = "NEW BEST!"
            newBest.fontSize = 18
            newBest.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1)
            newBest.position = CGPoint(x: size.width/2, y: size.height * 0.42)
            addChild(newBest)

            let starPulse = SKAction.sequence([
                SKAction.scale(to: 1.2, duration: 0.3),
                SKAction.scale(to: 1.0, duration: 0.3)
            ])
            newBest.run(SKAction.repeatForever(starPulse))
        }

        // Restart button
        addButton(title: "PLAY AGAIN", position: CGPoint(x: size.width/2, y: size.height * 0.32),
                  color: SKColor(red: 0.2, green: 0.75, blue: 0.3, alpha: 1), name: "restartButton")

        // Menu button
        addButton(title: "MENU", position: CGPoint(x: size.width/2, y: size.height * 0.21),
                  color: SKColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1), name: "menuButton")

        // Stars decoration
        for _ in 0..<20 {
            addStar()
        }
    }

    private func addButton(title: String, position: CGPoint, color: SKColor, name: String) {
        let button = SKShapeNode(rectOf: CGSize(width: 200, height: 50), cornerRadius: 25)
        button.fillColor = color
        button.strokeColor = SKColor(white: 1, alpha: 0.4)
        button.lineWidth = 1.5
        button.position = position
        button.zPosition = 10
        button.name = name
        addChild(button)

        let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
        label.text = title
        label.fontSize = 20
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.name = name
        button.addChild(label)
    }

    private func addStar() {
        let star = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...3))
        star.fillColor = SKColor(white: 1, alpha: CGFloat.random(in: 0.3...0.8))
        star.strokeColor = .clear
        star.position = CGPoint(x: CGFloat.random(in: 0...size.width),
                                y: CGFloat.random(in: 0...size.height))
        star.zPosition = 1
        addChild(star)

        let twinkle = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.1, duration: Double.random(in: 0.5...1.5)),
            SKAction.fadeAlpha(to: CGFloat.random(in: 0.4...0.9), duration: Double.random(in: 0.5...1.5))
        ])
        star.run(SKAction.repeatForever(twinkle))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let loc = touch.location(in: self)
        let nodes = self.nodes(at: loc)

        if nodes.contains(where: { $0.name == "restartButton" }) {
            let scene = GameScene(size: size)
            scene.scaleMode = .aspectFill
            view?.presentScene(scene, transition: SKTransition.doorway(withDuration: 0.5))
        } else if nodes.contains(where: { $0.name == "menuButton" }) {
            let scene = MenuScene(size: size)
            scene.scaleMode = .aspectFill
            view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.4))
        }
    }
}
