import UIKit
import SpriteKit
import AVFoundation
import Dispatch

// MARK: - 물리 카테고리 열거형 정의

enum PhysicsCategory: UInt32 {
    case fish = 1
    case ground = 2
    case outline = 4
}


// MARK: - 게임 씬 클래스 정의

class GameScene: SKScene, SKPhysicsContactDelegate {
    //게임 오버시
    var gameOverLabel: SKLabelNode!
    var restartButton: UIButton!

    var score = 0
    var scoreLabel: SKLabelNode!
    var mwscore = 0
    var fishPreviewNode: SKSpriteNode!
    var fishIndex = 0
    
    //효과음 배열로 동시 중복 재생
    var soundEffectPlayers: [AVAudioPlayer] = []
    var isClickable = true
    //점수 표시
    func setupScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = SKColor.black
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 100)
        scoreLabel.text = "\(score)"
        addChild(scoreLabel)
        
        // gameOverLabel을 초기화합니다.
        gameOverLabel = SKLabelNode(fontNamed: "")
        gameOverLabel.fontSize = 36
        gameOverLabel.fontColor = SKColor.red
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2)
        gameOverLabel.text = "게임 오버"
        gameOverLabel.isHidden = true
        addChild(gameOverLabel)
    }

    func enableClickAfterDelay() {
        // 클릭이 가능한 경우에만 실행
        guard isClickable else { return }
        
        // 클릭 가능 상태를 false로 변경
        isClickable = false
        
        // 비동기로 1초 후에 클릭 가능한 상태로 변경
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            // 클릭 가능 상태를 true로 변경
            self.isClickable = true
            print("1초 후에 클릭 가능")
        }
    }
    
    func addMenuButton() {
        let menuButton = UIButton(type: .custom)
        menuButton.setImage(UIImage(named: "reset"), for: .normal)
        menuButton.backgroundColor = UIColor(red: 135/255.0, green: 204/255.0, blue: 171/255.0, alpha: 1.0)
        menuButton.layer.cornerRadius = 9 // 버튼을 라운드 처리
        menuButton.frame = CGRect(x: 50, y: 60, width: 85, height: 85)
        menuButton.addTarget(self, action: #selector(menuButtonTapped), for: .touchUpInside)

        if let view = view {
            view.addSubview(menuButton)
        }
    }
    func resetGame() {
        // 점수 초기화
        score = 0
        scoreLabel.text = "\(score)"
        mwscore = 0
        // 모든 기물 제거
        removeAllFishs()
        gameOverLabel.isHidden = true
        if let restartButton = restartButton {
            restartButton.removeFromSuperview()
        } else {
            // restartButton이 nil일 때의 처리
            print("restartButton is nil")
        }
        // 게임 일시 중지 해제
        self.view?.isPaused = false
    }
    @objc func menuButtonTapped() {
        // 메뉴 버튼이 탭되었을 때의 동작을 처리합니다.
        print("리셋")
        resetGame()
        addGround()
        addLeftWall()
        addRightWall()
        addOutLine()
        addFishPreviewNode()
        updateFishPreview()
        addBackground()
        addOrder()
    }


    
    // MARK: 씬이 뷰로 이동할 때 호출되는 메서드

    override func didMove(to view: SKView) {
        self.size = view.bounds.size

        // 물리 세계 설정
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        backgroundColor = SKColor(red: 135/255.0, green: 204/255.0, blue: 171/255.0, alpha: 1.0)
          
        // 지면, 좌벽, 우벽 추가
        addGround()
        addLeftWall()
        addRightWall()
        
        addMenuButton()

        setupScoreLabel()
        
        // 개체 미리보기 노드 추가
        addFishPreviewNode()
        // 초기 미리보기 업데이트
        updateFishPreview()
        addOutLine()
        addBackground()
        addOrder()
        // 효과음
        if let soundFilePath = Bundle.main.path(forResource: "060_뽀옹", ofType: "mp3") {
             let soundFileURL = URL(fileURLWithPath: soundFilePath)

             do {
                 // 여러 AVAudioPlayer 인스턴스 생성
                 for _ in 0..<3 {
                     let soundEffectPlayer = try AVAudioPlayer(contentsOf: soundFileURL)
                     soundEffectPlayer.prepareToPlay()
                     soundEffectPlayers.append(soundEffectPlayer)
                 }
             } catch {
                 // 오류 처리
                 print("Error initializing AVAudioPlayer for sound effect: \(error)")
             }
         } else {
             // 파일을 찾을 수 없음
             print("Sound effect file not found.")
         }
    }
    // 배경화면
    func addBackground() {
        let backgroundNode = SKSpriteNode(imageNamed: "background.jpg")
        backgroundNode.size = self.size
        backgroundNode.position = CGPoint(x: self.size.width / 2, y: self.size.height / 2)
        backgroundNode.zPosition = -1 // 배경을 화면 뒤로 보내어 다른 노드들 위에 나타나게 합니다.
        addChild(backgroundNode)
    }
    
    func addOrder() {
        let orderImageName = "order"
        let orderNode = SKSpriteNode(imageNamed: orderImageName)
        let imageSize = CGSize(width: 400, height: 300)
        orderNode.size = imageSize
        
        // 화면 중앙으로 위치시키기
        orderNode.position = CGPoint(x: size.width / 2, y: size.height - 230)
        
        addChild(orderNode)
    }
    func addFishPreviewNode() {
        // 초기 바다 친구들 미리보기
        fishPreviewNode = SKSpriteNode(imageNamed: "\(FISHS01[0].name).png")
        fishPreviewNode.size = CGSize(width: 50, height: 50)
        fishPreviewNode.position = CGPoint(x: size.width - 70, y: size.height - 100)
        addChild(fishPreviewNode)
    }

    func updateFishPreview() {
        //인덱스 범위 지정
        let nextfishIndex = Int.random(in: 0..<4)
        fishIndex = nextfishIndex
        let nextFish = FISHS01[nextfishIndex]
        fishPreviewNode.texture = SKTexture(imageNamed: "\(nextFish.name).png")
    }
    
    // MARK: 화면 터치 시 호출되는 메서드

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // 클릭 가능한지 여부 확인 후 동작
        if isClickable {
            for touch in touches {
                let location = touch.location(in: self)
                addFishAtLocation(location)
                updateFishPreview()
            }
            // 1초 간격으로 클릭 가능 여부 업데이트
            enableClickAfterDelay()
        }
    }

    // MARK: 땅 추가 메서드

    func addGround() {
        let ground = SKSpriteNode(color: .clear, size: CGSize(width: size.width, height: 60))
        ground.position = CGPoint(x: size.width / 2, y: 100)
        ground.physicsBody = SKPhysicsBody(rectangleOf: ground.size)
        ground.physicsBody?.isDynamic = false
        ground.physicsBody?.categoryBitMask = PhysicsCategory.ground.rawValue
        addChild(ground)
    }

    // MARK: 좌벽 추가 메서드

    func addLeftWall() {
        let leftWall = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: size.height))
        leftWall.position = CGPoint(x: 1, y: size.height / 2)
        leftWall.physicsBody = SKPhysicsBody(rectangleOf: leftWall.size)
        leftWall.physicsBody?.isDynamic = false
        leftWall.physicsBody?.categoryBitMask = PhysicsCategory.ground.rawValue
        addChild(leftWall)
    }

    // MARK: 우벽 추가 메서드

    func addRightWall() {
        let rightWall = SKSpriteNode(color: .clear, size: CGSize(width: 1, height: size.height))
        rightWall.position = CGPoint(x: size.width - 1, y: size.height / 2)
        rightWall.physicsBody = SKPhysicsBody(rectangleOf: rightWall.size)
        rightWall.physicsBody?.isDynamic = false
        rightWall.physicsBody?.categoryBitMask = PhysicsCategory.ground.rawValue
        addChild(rightWall)
    }

    // MARK: 아웃라인 추가 메서드

    func addOutLine() {
        let customColor = UIColor(red: 109/255.0, green: 191/255.0, blue: 150/255.0, alpha: 1.0)
        let outLine = SKSpriteNode(color: customColor , size: CGSize(width: size.width, height: 1))
        
        outLine.position = CGPoint(x: size.width / 2, y:  size.height - 350 )
        outLine.physicsBody = SKPhysicsBody(rectangleOf: outLine.size)
        outLine.physicsBody?.isDynamic = false
        outLine.physicsBody?.categoryBitMask = PhysicsCategory.outline.rawValue
        outLine.physicsBody?.contactTestBitMask = PhysicsCategory.fish.rawValue
        addChild(outLine)
    }
    
    // MARK: 물고기 추가 메서드
    func addFishAtLocation(_ location: CGPoint) {
        let index = fishIndex
        let fish = FISHS01[index]
        let radius = CGFloat(fish.radius)

        // 특정 위치에 이미 동일한 유형의 개체가 있는지 확인합니다.
        let existingFish = self.nodes(at: location).compactMap { $0 as? SKSpriteNode }
            .first { $0.name == fish.name }

        if let existingFish = existingFish {
            // 기존 바다 친구들을 병합합니다.
            existingFish.run(SKAction.scale(by: 1.5, duration: 0.2)) {
                existingFish.run(SKAction.scale(by: 0.67, duration: 0.2))
            }
        } else {
            // 새로운 바다친구 생성합니다.
            let body = SKSpriteNode(imageNamed: "\(fish.name).png")
            body.size = CGSize(width: radius * 2, height: radius * 2)
            body.physicsBody = SKPhysicsBody(circleOfRadius: radius)
            
            // 위치에 대한 특정 y값을 고정합니다.
            let fixedYValue: CGFloat = self.size.height - 400
            body.position = CGPoint(x: location.x, y: fixedYValue)
            body.name = fish.name

            body.physicsBody = SKPhysicsBody(circleOfRadius: radius)
            body.physicsBody?.restitution = 0.3
            body.physicsBody?.isDynamic = true
            body.physicsBody?.categoryBitMask = PhysicsCategory.fish.rawValue
            body.physicsBody?.contactTestBitMask = PhysicsCategory.fish.rawValue

            addChild(body)
        }
    }
    
    // MARK: 충돌 감지 메서드

    func didBegin(_ contact: SKPhysicsContact) {

        if contact.bodyA.categoryBitMask == PhysicsCategory.fish.rawValue &&
           contact.bodyB.categoryBitMask == PhysicsCategory.outline.rawValue {
            fishDidTouchOutline()
        } else if contact.bodyA.categoryBitMask == PhysicsCategory.outline.rawValue &&
                  contact.bodyB.categoryBitMask == PhysicsCategory.fish.rawValue {
            fishDidTouchOutline()
        }
        
        // 두 개체가 충돌했을 때 호출됩니다.
        if contact.bodyA.categoryBitMask == PhysicsCategory.fish.rawValue &&
           contact.bodyB.categoryBitMask == PhysicsCategory.fish.rawValue {
            
            // 충돌한 두 개체의 노드 가져오기
            if let fishA = contact.bodyA.node as? SKSpriteNode,
               let fishB = contact.bodyB.node as? SKSpriteNode {
                
                // 두 개체가 같은지 확인하고 같다면 병합
                if fishA.name == fishB.name {
                    
                    // FISHS01 배열에서 fishA의 인덱스 가져오기
                    if let index = FISHS01.firstIndex(where: { $0.name == fishA.name }) {
                        if index == 9 {
                        }
                        else {
                            // 효과음
                            if let availablePlayer = soundEffectPlayers.first(where: { !$0.isPlaying }) {
                                availablePlayer.play()
                            }
                            // 인덱스를 1 증가 (증가시키려는 경우)
                            let newIndex = (index + 1) % FISHS01.count
                            // 새로운 개체 정보 가져오기
                            let newFish = FISHS01[newIndex]
                            
                            // 점수 계산
                            if newIndex == 1 {
                                score = score + 10
                            }
                            else if newIndex == 2 {
                                score = score + 30
                            }
                            else if newIndex == 3 {
                                score = score + 50
                            }
                            else if newIndex == 4 {
                                score = score + 100
                            }
                            else if newIndex == 5 {
                                score = score + 200
                            }
                            else if newIndex == 6 {
                                score = score + 400
                            }
                            else if newIndex == 7 {
                                score = score + 1000
                            }
                            else if newIndex == 8 {
                                score = score + 3000
                            }
                            else if newIndex == 9 {
                                score = score + 5000
                                mwscore  = mwscore + 1 // 고래 개수
                            }
                            scoreLabel.text = "\(score)"
                            
                            // 노드의 텍스처, 이름, 크기 변경
                            fishA.texture = SKTexture(imageNamed: "\(newFish.name).png")
                            fishA.name = newFish.name
                            fishA.size = CGSize(width: newFish.radius * 2, height: newFish.radius * 2)
                            
                            // 물리 바디 크기 업데이트
                            fishA.physicsBody = SKPhysicsBody(circleOfRadius: newFish.radius)
                            fishA.physicsBody?.restitution = 0.5
                            fishA.physicsBody?.isDynamic = true
                            fishA.physicsBody?.categoryBitMask = PhysicsCategory.fish.rawValue
                            fishA.physicsBody?.contactTestBitMask = PhysicsCategory.fish.rawValue
                            
                            // 병합 없이 바로 두 개체를 제거합니다
                            fishB.removeFromParent()
                        }
                    }
                }
            }
        }
    }
    @objc func restartButtonTapped() {
        menuButtonTapped()
    }

    func removeAllFishs() {
        // 씬에서 모든 SKSpriteNode(개체) 노드 제거
        self.children.forEach { node in
            if node is SKSpriteNode {
                node.removeFromParent()
            }
        }
    }
    
    //게임 승리시 이미지 변경
    func changeImagesOnGameWin() {
        updateFishImages()
    }
    //게임 패배시 이미지 변경
    func changeImagesOnGameLose() {
        updateFishImages()

    }
    
    func updateFishImages() {
        // 씬에서 모든 SKSpriteNode(개체) 노드 찾기
        let fishNodes = self.children.compactMap { $0 as? SKSpriteNode }

        // 각각의 개체에 대해 이미지 업데이트
        for fishNode in fishNodes {
            if let fish = FISHS01.first(where: { $0.name == fishNode.name }) {
                // 현재 물고기의 인덱스 찾기
                if let currentIndex = FISHS01.firstIndex(where: { $0.name == fishNode.name }) {
                    // 현재 물고기의 인덱스를 기반으로 FISHS03의 이미지로 변경
                    let newIndex = currentIndex % FISHS03.count
                    
                    let newFish = (mwscore != 0) ? FISHS02[newIndex] : FISHS03[newIndex]

                    
                    // 노드의 텍스처, 이름, 크기 변경
                    fishNode.texture = SKTexture(imageNamed: "\(newFish.name).png")
                    fishNode.name = newFish.name
                    fishNode.size = CGSize(width: newFish.radius * 2, height: newFish.radius * 2)
                    
                    // 물리 바디 크기 업데이트
                    fishNode.physicsBody = SKPhysicsBody(circleOfRadius: newFish.radius)
                    fishNode.physicsBody?.restitution = 0.5
                    fishNode.physicsBody?.isDynamic = true
                    fishNode.physicsBody?.categoryBitMask = PhysicsCategory.fish.rawValue
                    fishNode.physicsBody?.contactTestBitMask = PhysicsCategory.fish.rawValue

                }
            }
        }
    }

    
    // MARK: 충돌 아웃라인 감지
    func fishDidTouchOutline() {
        // 물고기가 선에 닿았을 때의 동작을 여기에 구현합니다.
        print("bye")
        // 게임 오버 화면 표시
        if mwscore != 0 {
            changeImagesOnGameWin()
        } else {
            changeImagesOnGameLose()
        }
        showGameOverScreen()
        // 씬 일시 중지
        view?.isPaused = true

    }

    
    func showGameOverScreen() {
        if mwscore != 0 {
            gameOverLabel.text = "게임 승리  \n점수: \(score)"
        } else {
            gameOverLabel.text = "게임 패배  \n점수: \(score)"
        }
        gameOverLabel.isHidden = false
        gameOverLabel.fontColor = SKColor.white
        gameOverLabel.fontSize = 40
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 70)

        restartButton = UIButton(type: .custom)
        restartButton.setTitle("다시하기", for: .normal)
        restartButton.setTitleColor(UIColor.black, for: .normal)
        restartButton.backgroundColor = UIColor(red: CGFloat(3) / 255.0, green: CGFloat(140) / 255.0, blue: CGFloat(90) / 255.0, alpha: 1.0)
        restartButton.layer.cornerRadius = 15 // 라운드 사각형 조절
        restartButton.layer.borderWidth = 2 // 테두리 추가
        restartButton.layer.borderColor = UIColor.black.cgColor // 테두리 색상 설정
        restartButton.frame = CGRect(x: size.width / 2 - 100, y: size.height / 2 - 50, width: 200, height: 100) // 가로 크기를 조금 넓게 조정
        restartButton.addTarget(self, action: #selector(restartButtonTapped), for: .touchUpInside)

        if let view = view {
            view.addSubview(restartButton)
        }
    }


}
