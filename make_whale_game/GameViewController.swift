
import UIKit
import SpriteKit
import GameplayKit
import AVFoundation

class GameViewController: UIViewController {
    
    var backgroundMusicPlayer: AVAudioPlayer?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 배경 음악 파일의 경로를 가져오기
        if let musicFilePath = Bundle.main.path(forResource: "Dog and Pony Show", ofType: "mp3") {
            let musicURL = URL(fileURLWithPath: musicFilePath)

            do {
                // AVAudioPlayer 인스턴스 생성 및 설정
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: musicURL)
                backgroundMusicPlayer?.numberOfLoops = -1 // 반복 재생, -1은 무한 반복을 의미
                backgroundMusicPlayer?.prepareToPlay()

                // 음악 재생
                backgroundMusicPlayer?.play()
            } catch {
                // 오류 처리
                print("Error initializing AVAudioPlayer: \(error)")
            }
        } else {
            // 파일을 찾을 수 없음
            print("Background music file not found.")
        }
        
        if let view = self.view as! SKView? {
            let scene = GameScene(size: view.bounds.size)
            scene.scaleMode = .resizeFill
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }
}
