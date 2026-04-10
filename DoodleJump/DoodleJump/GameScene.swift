import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Categories
    struct PhysicsCategory {
        static let none:      UInt32 = 0
        static let player:    UInt32 = 0b001
        static let platform:  UInt32 = 0b010
        static let enemy:     UInt32 = 0b100
        static let spring:    UInt32 = 0b1000
    }

    // MARK: - Nodes
    private var player: SKSpriteNode!
    private var platformsNode = SKNode()
    private var cameraNode = SKCameraNode()
    private var scoreLabel: SKLabelNode!
    private var backgroundNode: SKSpriteNode!

    // MARK: - State
    private var score = 0
    private var highestY: CGFloat = 0
    private var isGameOver = false
    private var motionManager = CMMotionManager()
    private var lastUpdateTime: TimeInterval = 0
    private var cameraTargetY: CGFloat = 0

    // MARK: - Platform config
    private let platformWidth: CGFloat = 80
    private let platformHeight: CGFloat = 16
    private let jumpForce: CGFloat = 750
    private let springJumpForce: CGFloat = 1200
    private var screenWidth: CGFloat { size.width }
    private var screenHeight: CGFloat { size.height }

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        setupPhysics()
        setupCamera()
        setupBackground()
        setupPlayer()
        setupInitialPlatforms()
        setupHUD()
        startMotionUpdates()
    }

    // MARK: - Setup

    private func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self
        physicsBody = SKPhysicsBody(edgeLoopFrom: CGRect(x: -screenWidth/2, y: -screenHeight*50, width: screenWidth, height: screenHeight*100))
    }

    private func setupCamera() {
        addChild(cameraNode)
        camera = cameraNode
        cameraNode.position = CGPoint(x: 0, y: 0)
    }

    private func setupBackground() {
        backgroundNode = SKSpriteNode(color: SKColor(red: 0.53, green: 0.81, blue: 0.98, alpha: 1.0), size: CGSize(width: screenWidth, height: screenHeight * 200))
        backgroundNode.position = CGPoint(x: 0, y: screenHeight * 100)
        backgroundNode.zPosition = -10
        addChild(backgroundNode)
    }

    private func setupPlayer() {
        player = SKSpriteNode(color: .green, size: CGSize(width: 44, height: 44))
        player.position = CGPoint(x: 0, y: 100)
        player.zPosition = 1
        player.name = "player"

        // Rounded look
        player.texture = makePlayerTexture()

        let body = SKPhysicsBody(rectangleOf: CGSize(width: 36, height: 36))
        body.categoryBitMask = PhysicsCategory.player
        body.contactTestBitMask = PhysicsCategory.platform | PhysicsCategory.spring
        body.collisionBitMask = PhysicsCategory.none
        body.allowsRotation = false
        body.restitution = 0
        body.linearDamping = 0
        player.physicsBody = body

        addChild(player)
        highestY = player.position.y
        cameraTargetY = 0
    }

    private func makePlayerTexture() -> SKTexture {
        let size = CGSize(width: 44, height: 44)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            UIColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 1).setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 10).fill()

            // eyes
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(x: 10, y: 12, width: 10, height: 10)).fill()
            UIBezierPath(ovalIn: CGRect(x: 24, y: 12, width: 10, height: 10)).fill()
            UIColor.black.setFill()
            UIBezierPath(ovalIn: CGRect(x: 13, y: 15, width: 5, height: 5)).fill()
            UIBezierPath(ovalIn: CGRect(x: 27, y: 15, width: 5, height: 5)).fill()

            // mouth
            UIColor.white.setFill()
            UIBezierPath(ovalIn: CGRect(x: 14, y: 28, width: 16, height: 8)).fill()
        }
        return SKTexture(image: img)
    }

    private func setupInitialPlatforms() {
        addChild(platformsNode)

        // Starting platform under player
        spawnPlatform(at: CGPoint(x: 0, y: 60), type: .normal)

        // Spread platforms going up
        var y: CGFloat = 160
        while y < screenHeight * 1.5 {
            let x = CGFloat.random(in: -screenWidth/2 + platformWidth/2 ... screenWidth/2 - platformWidth/2)
            let type = platformType(for: y)
            spawnPlatform(at: CGPoint(x: x, y: y), type: type)
            y += CGFloat.random(in: 70...120)
        }
    }

    private func setupHUD() {
        scoreLabel = SKLabelNode(fontNamed: "AvenirNext-Bold")
        scoreLabel.fontSize = 28
        scoreLabel.fontColor = .white
        scoreLabel.horizontalAlignmentMode = .center
        scoreLabel.position = CGPoint(x: 0, y: screenHeight/2 - 60)
        scoreLabel.zPosition = 100
        scoreLabel.text = "0"
        cameraNode.addChild(scoreLabel)

        // Score shadow
        let shadow = SKLabelNode(fontNamed: "AvenirNext-Bold")
        shadow.fontSize = 28
        shadow.fontColor = SKColor(white: 0, alpha: 0.3)
        shadow.horizontalAlignmentMode = .center
        shadow.position = CGPoint(x: 2, y: -2)
        shadow.zPosition = -1
        shadow.text = "0"
        shadow.name = "scoreShadow"
        scoreLabel.addChild(shadow)
    }

    private func startMotionUpdates() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 1.0/60.0
            motionManager.startAccelerometerUpdates()
        }
    }

    // MARK: - Platform Types

    enum PlatformType {
        case normal, moving, breakable, spring
    }

    private func platformType(for y: CGFloat) -> PlatformType {
        let difficulty = min(y / 2000, 1.0)
        let r = Double.random(in: 0...1)
        if r < 0.05 + difficulty * 0.1 { return .spring }
        if r < 0.15 + difficulty * 0.2 { return .moving }
        if r < 0.20 + difficulty * 0.15 { return .breakable }
        return .normal
    }

    private func spawnPlatform(at position: CGPoint, type: PlatformType) {
        let platform: SKSpriteNode

        switch type {
        case .normal:
            platform = makePlatformNode(color: SKColor(red: 0.2, green: 0.75, blue: 0.3, alpha: 1), name: "platform_normal")
        case .moving:
            platform = makePlatformNode(color: SKColor(red: 0.2, green: 0.5, blue: 0.95, alpha: 1), name: "platform_moving")
            let move = SKAction.sequence([
                SKAction.moveBy(x: 80, y: 0, duration: 1.2),
                SKAction.moveBy(x: -80, y: 0, duration: 1.2)
            ])
            platform.run(SKAction.repeatForever(move))
        case .breakable:
            platform = makePlatformNode(color: SKColor(red: 0.9, green: 0.5, blue: 0.1, alpha: 1), name: "platform_breakable")
        case .spring:
            platform = makePlatformNode(color: SKColor(red: 0.9, green: 0.2, blue: 0.2, alpha: 1), name: "platform_spring")
            addSpring(to: platform)
        }

        platform.position = position
        platformsNode.addChild(platform)
    }

    private func makePlatformNode(color: SKColor, name: String) -> SKSpriteNode {
        let texture = makePlatformTexture(color: color)
        let node = SKSpriteNode(texture: texture, size: CGSize(width: platformWidth, height: platformHeight))
        node.name = name

        let body = SKPhysicsBody(rectangleOf: CGSize(width: platformWidth, height: platformHeight))
        body.isDynamic = false
        body.categoryBitMask = name == "platform_spring" ? PhysicsCategory.spring : PhysicsCategory.platform
        body.contactTestBitMask = PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.none
        node.physicsBody = body
        return node
    }

    private func makePlatformTexture(color: SKColor) -> SKTexture {
        let size = CGSize(width: platformWidth, height: platformHeight)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            color.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: 6).fill()
            UIColor.white.withAlphaComponent(0.3).setFill()
            UIBezierPath(roundedRect: CGRect(x: 4, y: 2, width: platformWidth - 8, height: 4), cornerRadius: 2).fill()
        }
        return SKTexture(image: img)
    }

    private func addSpring(to platform: SKSpriteNode) {
        let spring = SKShapeNode(rectOf: CGSize(width: 12, height: 14), cornerRadius: 3)
        spring.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1)
        spring.strokeColor = .clear
        spring.position = CGPoint(x: 0, y: platformHeight/2 + 7)
        spring.name = "spring_coil"
        spring.zPosition = 1
        platform.addChild(spring)
    }

    // MARK: - Game Loop

    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver else { return }

        let dt = lastUpdateTime == 0 ? 0 : currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        applyAccelerometer()
        wrapPlayerHorizontally()
        updateCamera(dt: dt)
        updateScore()
        generatePlatformsIfNeeded()
        removeOldPlatforms()
        checkGameOver()
    }

    private func applyAccelerometer() {
        guard let data = motionManager.accelerometerData else { return }
        let tilt = CGFloat(data.acceleration.x)
        let force = tilt * 600
        player.physicsBody?.velocity.dx = force
    }

    private func wrapPlayerHorizontally() {
        if player.position.x > screenWidth/2 + 22 {
            player.position.x = -screenWidth/2 - 22
        } else if player.position.x < -screenWidth/2 - 22 {
            player.position.x = screenWidth/2 + 22
        }
    }

    private func updateCamera(dt: TimeInterval) {
        let targetY = max(player.position.y, cameraTargetY)
        cameraTargetY = targetY
        let smoothing: CGFloat = 0.1
        cameraNode.position.y += (cameraTargetY - cameraNode.position.y) * smoothing
        backgroundNode.position.y = cameraNode.position.y
    }

    private func updateScore() {
        let newScore = max(0, Int((player.position.y - 100) / 10))
        if newScore > score {
            score = newScore
            scoreLabel.text = "\(score)"
            if let shadow = scoreLabel.childNode(withName: "scoreShadow") as? SKLabelNode {
                shadow.text = "\(score)"
            }
        }
    }

    private func generatePlatformsIfNeeded() {
        let topY = cameraNode.position.y + screenHeight/2 + 200
        var highestPlatformY: CGFloat = 0

        platformsNode.children.forEach {
            if $0.position.y > highestPlatformY { highestPlatformY = $0.position.y }
        }

        while highestPlatformY < topY {
            highestPlatformY += CGFloat.random(in: 70...120)
            let x = CGFloat.random(in: -screenWidth/2 + platformWidth/2 ... screenWidth/2 - platformWidth/2)
            spawnPlatform(at: CGPoint(x: x, y: highestPlatformY), type: platformType(for: highestPlatformY))
        }
    }

    private func removeOldPlatforms() {
        let cutoffY = cameraNode.position.y - screenHeight
        platformsNode.children.filter { $0.position.y < cutoffY }.forEach { $0.removeFromParent() }
    }

    private func checkGameOver() {
        if player.position.y < cameraNode.position.y - screenHeight/2 - 50 {
            triggerGameOver()
        }
    }

    // MARK: - Physics Contact

    func didBegin(_ contact: SKPhysicsContact) {
        guard !isGameOver else { return }

        let (bodyA, bodyB) = contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask
            ? (contact.bodyA, contact.bodyB)
            : (contact.bodyB, contact.bodyA)

        // Player lands on platform from above
        guard let playerBody = player.physicsBody,
              playerBody.velocity.dy <= 0 else { return }

        let platformMask = PhysicsCategory.platform | PhysicsCategory.spring

        if bodyA.categoryBitMask == PhysicsCategory.player,
           bodyB.categoryBitMask & platformMask != 0 {

            let node = bodyB.node

            if node?.name == "platform_breakable" {
                // Break and jump
                player.physicsBody?.velocity = CGVector(dx: player.physicsBody!.velocity.dx, dy: jumpForce)
                let shatter = SKAction.sequence([
                    SKAction.group([
                        SKAction.scale(to: 1.3, duration: 0.1),
                        SKAction.fadeOut(withDuration: 0.2)
                    ]),
                    SKAction.removeFromParent()
                ])
                node?.run(shatter)
            } else if bodyB.categoryBitMask == PhysicsCategory.spring || node?.name == "platform_spring" {
                player.physicsBody?.velocity = CGVector(dx: player.physicsBody!.velocity.dx, dy: springJumpForce)
                bounceFeedback()
            } else {
                player.physicsBody?.velocity = CGVector(dx: player.physicsBody!.velocity.dx, dy: jumpForce)
            }

            jumpFeedback()
        }
    }

    private func jumpFeedback() {
        let squash = SKAction.sequence([
            SKAction.scaleX(to: 1.3, y: 0.7, duration: 0.05),
            SKAction.scaleX(to: 1.0, y: 1.0, duration: 0.1)
        ])
        player.run(squash)
    }

    private func bounceFeedback() {
        let pop = SKAction.sequence([
            SKAction.scaleX(to: 0.8, y: 1.4, duration: 0.05),
            SKAction.scaleX(to: 1.0, y: 1.0, duration: 0.1)
        ])
        player.run(pop)
    }

    // MARK: - Game Over

    private func triggerGameOver() {
        isGameOver = true
        motionManager.stopAccelerometerUpdates()

        let fall = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.wait(forDuration: 0.5)
        ])
        player.run(fall) { [weak self] in
            self?.showGameOver()
        }
    }

    private func showGameOver() {
        let scene = GameOverScene(size: size, score: score)
        scene.scaleMode = .aspectFill
        view?.presentScene(scene, transition: SKTransition.fade(withDuration: 0.5))
    }

    // MARK: - Touch (simulator fallback)

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard motionManager.accelerometerData == nil else { return }
        guard let touch = touches.first else { return }
        let dx = touch.location(in: self).x - touch.previousLocation(in: self).x
        player.physicsBody?.velocity.dx = dx * 8
    }
}
