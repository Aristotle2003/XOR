import SwiftUI
import SpriteKit
import Lottie
import UIKit
import CoreMotion
import Combine
import AVFoundation

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        if hex.count == 6 {
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        } else {
            (a, r, g, b) = (255, 0, 0, 0) // Default to black
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

class AudioManager {
    static let shared = AudioManager()
    var backgroundMusicPlayer: AVAudioPlayer?

    private init() {
        setupAudioSession()
        setupBackgroundMusic()
    }
    
    func adjustMusicPlayback(isPlaying: Bool) {
        if isPlaying {
            playBackgroundMusic()
        } else {
            pauseBackgroundMusic()
        }
    }

    func setupBackgroundMusic() {
        guard let bundlePath = Bundle.main.path(forResource: "Automatica", ofType: "mp3") else { return }
        let url = URL(fileURLWithPath: bundlePath)
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.prepareToPlay()
            backgroundMusicPlayer?.numberOfLoops = -1  // Infinite looping
        } catch {
            print("Error setting up audio player: \(error)")
        }
    }

    func playBackgroundMusic() {
        backgroundMusicPlayer?.play()
    }

    func pauseBackgroundMusic() {
        backgroundMusicPlayer?.pause()
    }

    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer?.currentTime = 0  // Reset the time to start from beginning
    }
}

extension AudioManager {
    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio Session error: \(error)")
        }
    }
}


struct ContentView: View {
    @State private var showMenu = false
    
    var body: some View {
        NavigationView {
            if showMenu {
                MenuView()
            } else {
                SpriteKitContainerView(showMenu: $showMenu)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// UIViewRepresentable wrapper for UIKit integration with SpriteKit
struct SpriteKitContainerView: UIViewControllerRepresentable {
    @Binding var showMenu: Bool
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = LandscapeOnlyViewController()
        viewController.showMenu = $showMenu
        let skView = SKView(frame: UIScreen.main.bounds)
        
        let scene = GameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        scene.showMenu = $showMenu
        
        skView.presentScene(scene)
        viewController.view.addSubview(skView)
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // Here you could update parts of your UI or scene based on state changes
    }
}

// Custom UIViewController that enforces landscape orientation
class LandscapeOnlyViewController: UIViewController {
    var showMenu: Binding<Bool>?
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscape
    }

    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .landscapeLeft
    }
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var animationViews: [String: LottieAnimationView] = [:]
    var showMenu: Binding<Bool>?
    let motionManager = CMMotionManager()
    
    override func didMove(to view: SKView) {
        setupBackground()
        
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsWorld.gravity = CGVector(dx: 0, dy: -1.0)
        physicsWorld.contactDelegate = self
        physicsBody?.restitution = 1.0
        
        addLottieAnimations()
        addStartingButton()
        
        startGyroscopeUpdates()
    }
    
    func startGyroscopeUpdates() {
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 0.1
            motionManager.startGyroUpdates(to: OperationQueue.main) { [weak self] (gyroData, error) in
                if let rotationRate = gyroData?.rotationRate {
                    self?.handleGyroData(rotationRate: rotationRate)
                }
            }
        }
    }
    
    func handleGyroData(rotationRate: CMRotationRate) {
        let rotationRateX = CGFloat(rotationRate.x)
        let rotationRateY = CGFloat(rotationRate.y)
        
        // Update Lottie animations based on gyroscope data
        for animationView in animationViews.values {
            animationView.center.x += rotationRateX * 10
            animationView.center.y += rotationRateY * 10
        }
    }
    
    override func willMove(from view: SKView) {
        motionManager.stopGyroUpdates()
    }
    
    func setupBackground() {
            let background = SKSpriteNode(imageNamed: "Main Page Background color")
            background.position = CGPoint(x: size.width / 2, y: size.height / 2)
            background.size = CGSize(width: size.width, height: size.height)
            background.scale(to: CGSize(width: size.width+20, height: size.height+20))
            background.zPosition = -1
            addChild(background)
    }
        
    
    func addLottieAnimations() {
        let animationNames = ["Main Page 1-0 Light1 1", "Main Page 0-1 Light1 1", "Main Page 0-1 Light0 1", "Main Page 1-0 Light0 1", "Main Page 0-1 Light2 1", "Main Page 1-0 Light2 1"]
        let size = CGSize(width: UIScreen.main.bounds.height / 4, height: UIScreen.main.bounds.height / 4)
    
        // Positions calculation
        let leftColumnX1 = size.width / 1.73
        let leftColumnX2 = leftColumnX1 + size.width * 1.15
        let rightColumnX1 = self.size.width - size.width / 1.73
        let rightColumnX2 = rightColumnX1 - size.width * 1.15
        let startY = size.height / 2
        
        var animationNodes = [SKSpriteNode]()
        
        // First 4 animations on the left side
        addAnimation(animationName: animationNames[0], xPos: leftColumnX1, yPos: startY, size: size, scale: 1.2, animationNodes: &animationNodes)
        addAnimation(animationName: animationNames[4], xPos: leftColumnX1, yPos: startY + size.height, size: size, scale: 1.2, animationNodes: &animationNodes)

        addAnimation(animationName: animationNames[3], xPos: leftColumnX1, yPos: startY + 3 * size.height, size: size, scale: 1.2, animationNodes: &animationNodes)
               
        // Next 4 animations on the left side
        addAnimation(animationName: animationNames[1], xPos: leftColumnX2, yPos: startY, size: size, scale: 1.2, animationNodes: &animationNodes)
        addAnimation(animationName: animationNames[3], xPos: leftColumnX2, yPos: startY + size.height, size: size,scale: 1.2, animationNodes: &animationNodes)
        
        addAnimation(animationName: animationNames[1], xPos: leftColumnX2, yPos: startY + 3 * size.height, size: size,scale: 1.2, animationNodes: &animationNodes)
               
        // First 4 animations on the right side
        addAnimation(animationName: animationNames[4], xPos: rightColumnX1, yPos: startY, size: size, scale: 1.2, animationNodes: &animationNodes)
        addAnimation(animationName: animationNames[3], xPos: rightColumnX1, yPos: startY + size.height, size: size,scale: 1.2, animationNodes: &animationNodes)

        
        addAnimation(animationName: animationNames[0], xPos: rightColumnX1, yPos: startY + 3 * size.height, size: size,scale: 1.2, animationNodes: &animationNodes)
               
        // Next 4 animations on the right side
        addAnimation(animationName: animationNames[0], xPos: rightColumnX2, yPos: startY, size: size,scale: 1.2, animationNodes: &animationNodes)
        
        addAnimation(animationName: animationNames[5], xPos: rightColumnX2, yPos: startY + 2 * size.height, size: size,scale: 1.2, animationNodes: &animationNodes)
        addAnimation(animationName: animationNames[1], xPos: rightColumnX2, yPos: startY + 3 * size.height, size: size,scale: 1.2, animationNodes: &animationNodes)
               
        // Last 2 animations randomly placed
        addAnimation(animationName: animationNames[1], xPos: rightColumnX2 - size.width*1.15, yPos: CGFloat.random(in: size.height / 2...self.size.height - size.height / 2), size: size, scale: 1.2, animationNodes: &animationNodes)
        addAnimation(animationName: animationNames[3], xPos: leftColumnX2 + size.width*1.15, yPos: CGFloat.random(in: size.height / 2...self.size.height - size.height / 2), size: size,scale: 1.2, animationNodes: &animationNodes)
               
        // Hold the state for 2 seconds before starting the animations
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            for node in animationNodes {
                node.physicsBody?.isDynamic = true
            }
        }
    }

    private func addAnimation(animationName: String, xPos: CGFloat, yPos: CGFloat, size: CGSize, scale: CGFloat, animationNodes: inout [SKSpriteNode]) {
            
            let spriteNode = SKSpriteNode(color: .clear, size: size)
            spriteNode.position = CGPoint(x: xPos, y: yPos)
            spriteNode.physicsBody = SKPhysicsBody(rectangleOf: spriteNode.size)
            spriteNode.physicsBody?.isDynamic = false
            spriteNode.physicsBody?.restitution = 1.0
            
            let animationView = LottieAnimationView(name: animationName)
            animationView.frame = CGRect(x: 0, y: 0, width: size.width * scale, height: size.height * scale)
            animationView.contentMode = .scaleAspectFit
            animationView.loopMode = .playOnce
            animationView.isUserInteractionEnabled = true
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(playAnimation(_:)))
            animationView.addGestureRecognizer(tapGesture)
            
            if let sceneView = self.view {
                sceneView.addSubview(animationView)
            }
            
            animationView.center = CGPoint(x: spriteNode.size.width / 2, y: spriteNode.size.height / 2)
            
            let uniqueID = UUID().uuidString
            spriteNode.name = uniqueID
            animationViews[uniqueID] = animationView
            
            addChild(spriteNode)
            animationNodes.append(spriteNode)
        }
        
        func addStartingButton() {
            @AppStorage("languageEnabled") var languageEnabled: Bool = false
            
            let animationView = LottieAnimationView(name: "Starting Button")
            animationView.frame = CGRect(x: (view?.frame.width ?? 0) / 2 - 100, y: (view?.frame.height ?? 0) / 2 - 10, width: 200, height: 200)
            animationView.contentMode = .scaleAspectFit
            animationView.loopMode = .playOnce
            animationView.isUserInteractionEnabled = true
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(startingButtonTapped(_:)))
            animationView.addGestureRecognizer(tapGesture)
            if languageEnabled {
                let logoImageView = UIImageView(image: UIImage(named: "Main Page Logo Chinese"))
                    logoImageView.contentMode = .scaleAspectFit
                    logoImageView.frame = CGRect(x: (view?.frame.width ?? 0) / 2 - 247, y: (view?.frame.height ?? 0) / 2 - 130, width: 493, height: 200)
                    
                    // Add the logo UIImageView to the view
                    self.view?.addSubview(logoImageView)
            } else {
                let logoImageView = UIImageView(image: UIImage(named: "Main Page Logo"))
                    logoImageView.contentMode = .scaleAspectFit
                    logoImageView.frame = CGRect(x: (view?.frame.width ?? 0) / 2 - 247, y: (view?.frame.height ?? 0) / 2 - 130, width: 493, height: 200)
                    
                    // Add the logo UIImageView to the view
                    self.view?.addSubview(logoImageView)
            }
            
            
            self.view?.addSubview(animationView)
        }
        
        @objc func startingButtonTapped(_ sender: UITapGestureRecognizer) {
        
            let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
            feedbackGenerator.prepare()
            feedbackGenerator.impactOccurred()

            if let animationView = sender.view as? LottieAnimationView {
                animationView.play { [weak self] _ in
                    self?.showMenu?.wrappedValue = true
                }
            }
        }
        
        @objc func playAnimation(_ sender: UITapGestureRecognizer) {
            if let animationView = sender.view as? LottieAnimationView {
                animationView.play { [weak self] _ in
                    animationView.currentProgress = 1.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self?.resetAnimation(animationView)
                    }
                }
            }
        }
        
        func resetAnimation(_ animationView: LottieAnimationView) {
            animationView.stop()
            animationView.currentProgress = 0
        }
        
        override func update(_ currentTime: TimeInterval) {
            for (nodeName, animationView) in animationViews {
                if let node = childNode(withName: nodeName) as? SKSpriteNode {
                    animationView.center = CGPoint(x: node.position.x, y: size.height - node.position.y)
                }
            }
        }
        
        override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            guard let touch = touches.first else { return }
            let location = touch.location(in: self.view)
            
            for animationView in animationViews.values {
                if animationView.frame.contains(location) {
                    animationView.play { [weak self] _ in
                        // Manually set to the last frame
                        animationView.currentProgress = 1.0
                        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                            self?.resetAnimation(animationView)
                        }
                    }
                }
            }
        }
        
        func didBegin(_ contact: SKPhysicsContact) {
            let nodeA = contact.bodyA.node
            let nodeB = contact.bodyB.node
            print("Collision detected between \(nodeA?.name ?? "") and \(nodeB?.name ?? "")")
        }
        
    }

struct LetterView: View{
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    var body: some View{
        ScrollView {
            if languageEnabled{
                Text("""
                亲爱的用户，

                您好！在您打开这封信的瞬间，便已迈入了一个精彩纷呈的技术世界。这是一场关于芯片、智能和未来的探险，而这一切的基础，都源自我们日常电子设备中不起眼却至关重要的基本组件——布尔逻辑门。

                在全球化的大背景下，芯片技术已成为国家竞争力的重要标志。我们中国人在芯片战争中一直面临着重大挑战和压力，常常感到被“卡脖子”。然而，希望从来未曾远离，唯有通过教育和培养新一代的工程师和科学家，我们才有机会翻盘。这款应用便是在这样的背景下应运而生，目的是为了启迪和培养未来的技术人才，让他们从小就对芯片技术有所认知和理解。

                布尔逻辑门是构建现代电子计算设备的基石。简单来说，布尔逻辑是一种用于电路设计的数学系统，它使用二进制的1和0（开或关）两种状态来解决逻辑问题。布尔门，如AND、OR、NOT，是实现这些逻辑操作的物理或者电子装置，在处理信息和执行计算时发挥着至关重要的作用。

                无论是您手中的智能手机，还是家里的电脑，亦或是更为复杂的服务器和超级计算机，它们的核心部件——芯片，都是由这些基本的逻辑门组成的。这些逻辑门按照精妙绝伦的设计相互连接和互动，共同完成复杂的数据处理任务。

                通过本应用，用户不仅能够学习到布尔逻辑门的基本概念和工作原理，还能直观地看到这些逻辑门如何在芯片中实际运作，理解它们如何共同构建起强大的计算架构。我们希望通过这种直观和互动的学习方式，激发用户对科技的兴趣，尤其是对半导体技术的深入了解。

                接下来，让我为您详细介绍这款具有两种模式的互动软件：工具箱模式和关卡模式。

                在工具箱模式中，用户可以自由地探索和操作各种布尔逻辑门。这个模式旨在让用户通过实践学习逻辑门的基本原理和功能。您可以随意搭建和修改逻辑门的组合，实时看到不同配置下的电路行为。此外，界面右上角设有一个“信息”按钮，点击后会显示当前逻辑门的逻辑模式和真值表（Truth Table）。这不仅帮助用户理解每个逻辑门的工作原理，还可以通过直观的展示加深记忆。

                关卡模式提供了一系列挑战，要求用户根据给定的指令通过搭建和调整电路来点亮或熄灭特定的灯泡。每个关卡都设计有不同的难度和要求，逐步引导用户从简单的单门电路到复杂的多门组合。完成这些挑战不仅能够验证您对布尔逻辑门的理解和应用，还能增强解决实际问题的能力。

                在我们的应用设置中，您可以自由切换中英文界面，以便更好地理解专业术语。此外，您还可以根据个人喜好调整背景音乐的开关和音量，以创造理想的学习环境。我们也欢迎您通过亦或门的社交媒体平台与我们的开发团队联系，分享您的反馈和建议。

                感谢您的阅读和支持。希望您能在探索这款应用的过程中获得知识与灵感，为未来的科技旅程做好准备。我们相信，每一个小小的逻辑门，都有成就大大的梦想的潜力。

                期待您的反馈与建议，一起进步，共创未来！

                祝好，

                亦或门开发团队
                """)
                .padding(50)
                .foregroundColor(.white)
                .font(.system(size: 18))
            }else{
                Text("""
                Dear XOR’s Users,
                
                Hello! The moment you open this letter, you step into a fascinating world of technology. This journey explores chips, intelligence, and the future, all founded on an unassuming yet crucial component in our everyday electronic devices—the Boolean logic gates.
                
                In the context of globalization, chip technology has become a vital indicator of national competitiveness. With AI technology becoming the next highlight, understanding computer processors, a key component in AI development, is essential. This app was created against this backdrop to inspire and nurture future tech talents, ensuring they grasp the core technologies from an early age.
                
                Boolean logic gates are the cornerstone of modern electronic computing devices. Simply put, Boolean logic is a mathematical system used in circuit design that employs binary states—1 and 0 (on or off)—to solve logical problems. Gates like AND, OR, and NOT are physical or electronic devices that implement these operations, playing a crucial role in processing information and performing computations.
                
                Whether it’s your smartphone, home computer, or more complex servers and supercomputers, their core components—chips—are composed of these basic logic gates. These gates are intricately designed to interact and connect, jointly carrying out complex data processing tasks.
                
                With this app, users not only learn about the basic concepts and operating principles of Boolean logic gates but can also see how these gates function within chips, understanding how they collectively build powerful computing architectures. We aim to ignite interest in technology, particularly semiconductor technology, through this interactive and intuitive learning approach.
                
                Let me introduce you to the two interactive modes of this software: Toolbox Mode and Challenge Mode.
                
                In Toolbox Mode, users can freely explore and manipulate various Boolean logic gates. This mode is designed to allow users to learn the fundamental principles and functions of logic gates through practical experience. You can freely build and modify combinations of logic gates and see the behavior of circuits under different configurations. Additionally, an "Info" button in the top right corner of the interface displays the logical mode and truth table of the current logic gate, aiding in understanding each gate's functionality and reinforcing memory through visual display.
                
                Challenge Mode offers a series of challenges that require users to build and adjust circuits to light up or turn off specific bulbs according to given instructions. Each level is designed with different difficulties and requirements, gradually guiding users from simple single-gate circuits to complex multi-gate combinations. Completing these challenges not only validates your understanding and application of Boolean logic gates but also enhances your ability to solve real-world problems.
                
                In our app settings, you can also adjust background music to create the ideal learning environment, tailored to your personal preferences. We welcome you to connect with our development team via the various social media platforms of XOR, sharing your feedback and suggestions.
                
                Thank you for your attention and support. We hope that as you explore this app, you gain knowledge and inspiration, preparing you for a future journey in technology. We believe that every small logic gate has the potential to achieve great dreams.
                
                We look forward to your feedback and suggestions to improve together and create the future!
                
                Best regards,
                
                XOR Development Team
                """)
                .padding(50)
                .foregroundColor(.white)
                .font(.custom("Georgia", size: 18))
            }
        }
        .frame(maxWidth: UIScreen.main.bounds.width/1.5, maxHeight: UIScreen.main.bounds.height/1.5)
        .background(Color(hex: "315372").opacity(1))
        .cornerRadius(40)
        .edgesIgnoringSafeArea(.all)
    }
}

struct MenuView: View {
    @State private var navigateToComponents = false
    @State private var navigateToCircuits = false
    @State private var navigateToSettings = false
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    @AppStorage("openDeveloperLetter_firstappear") var openDeveloperLetter_firstappear: Bool = true
    @State private var openDeveloperLetter = false
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        
        NavigationStack {
            ZStack {
                let SettingsPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 70)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y:
                                                    UIScreen.main.bounds.height/1.8)
                
                if !openDeveloperLetter && !openDeveloperLetter_firstappear{
                    Button(action: {
                        navigateToSettings = true
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Settings Button Menu Page")
                            .frame(width: 50, height: 50)
                    }
                    .position(SettingsPosition)
                }
                
                
                if navigateToSettings && !openDeveloperLetter && !openDeveloperLetter_firstappear{
                    SettingsView()
                    Button(action: {
                        navigateToSettings = false
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Cancel Button")
                            .frame(width: 50, height: 50)
                    }
                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                }
                
                if !navigateToSettings && !openDeveloperLetter && !openDeveloperLetter_firstappear{
                    VStack {
                        Spacer()
                        
                        HStack{
                            Button(action: {
                                navigateToCircuits = true
                                generateHapticFeedbackMedium()
                            }, label: {
                                if languageEnabled {
                                    Image("Circuits Button Chinese")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 300, height: 300)
                                } else {
                                    Image("Circuits Button")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 300, height: 300)
                                }
                                
                            })
                            .navigationDestination(isPresented: $navigateToCircuits) {
                                ComponentsView()
                            }
                            
                            Button(action: {
                                navigateToComponents = true
                                generateHapticFeedbackMedium()
                            }, label: {
                                if languageEnabled {
                                    Image("Component Button Chinese")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 300, height: 300)
                                } else {
                                    Image("Component Button")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 300, height: 300)
                                }
                                
                            })
                            .navigationDestination(isPresented: $navigateToComponents) {
                                CircuitsView()
                            }
                            
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                        Spacer()
                    }
                    .edgesIgnoringSafeArea(.all)
                }
                
                if !navigateToSettings && !openDeveloperLetter && !openDeveloperLetter_firstappear{
                    Button(action: {
                        openDeveloperLetter_firstappear = false
                        openDeveloperLetter = true
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Open Developer Letter")
                            .frame(width: 50, height: 50)
                    }
                    .position(x: SettingsPosition.x - 90, y: 60)
                }

                if openDeveloperLetter || openDeveloperLetter_firstappear{
                    LetterView()
                    Button(action: {
                        openDeveloperLetter = false
                        openDeveloperLetter_firstappear = false
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Cancel Button")
                            .frame(width: 50, height: 50)
                    }
                    .position(x:UIScreen.main.bounds.width/1.25, y: UIScreen.main.bounds.height/4.0)
                    
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct ComponentsView: View {
    @AppStorage("currentPage") var currentPage: Int = 0
    @State private var navigateToMenu = false
    @State private var activeLink: Int? = nil
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    @EnvironmentObject var levelManager: LevelManager // 从环境中获取全局的 LevelManager 实例


    let totalLevels = 40
    let levelsPerPage = 10
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        let numberOfPages = (totalLevels - 1) / levelsPerPage + 1
        let columns = Array(repeating: GridItem(.flexible()), count: 5)
        
        NavigationStack{
        
            ZStack {
                VStack {
                    if currentPage < 3 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyVGrid(columns: columns, spacing: UIScreen.main.bounds.height/20) {
                                ForEach(0..<levelsPerPage, id: \.self) { index in
                                    let actualLevel = index + 1 + currentPage * levelsPerPage
                                    if actualLevel <= totalLevels {
                                        Button(action: {
                                            generateHapticFeedbackMedium()
                                            self.activeLink = actualLevel
                                        }) { //--------------------------------------------------
                                            ZStack {
                                                Image("Level \(actualLevel) Button")
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fit)
                                                    .frame(width: UIScreen.main.bounds.height / 4.5, height: UIScreen.main.bounds.height / 4.5)
                                                
                                                // 星星图标，表示该关卡是否已完成
                                                if levelManager.hasStarForLevel(level: actualLevel - 1) {
                                                    Image(systemName: "star.fill")
                                                        .resizable()
                                                        .frame(width: 30, height: 30)
                                                        .foregroundColor(.yellow)
                                                        .position(x: UIScreen.main.bounds.height / 6, y: UIScreen.main.bounds.height / 20)
                                                }
                                            }
                                        } //--------------------------------------------------
                                        .navigationDestination(isPresented: Binding<Bool>(
                                            get: { activeLink == actualLevel },
                                            set: { if !$0 { activeLink = nil } }
                                        )) {
                                            LevelView(level: actualLevel)
                                                .transition(.move(edge: .bottom))
                                        }
                                    }
                                }
                                
                            }
                            .position(x: UIScreen.main.bounds.width/2.25, y: UIScreen.main.bounds.height/2.35)
                        }
                        .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.height/1.3)
                    }
                    else {
                        if languageEnabled {
                            Image("COMING SOON Chinese")
                                .position(x: UIScreen.main.bounds.width/2.2, y: UIScreen.main.bounds.height/2)
                        } else {
                            Image("COMING SOON")
                                .position(x: UIScreen.main.bounds.width/2.2, y: UIScreen.main.bounds.height/2)
                        }
                        
                    }
                }
                .navigationBarHidden(true)
                .background(
                    Image("Level Page Background")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                        .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                        .edgesIgnoringSafeArea(.all)
                )
                
                if currentPage > 0 {
                    Button(action: {
                        if currentPage > 0 {
                            currentPage -= 1
                        }
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Previous Button in Level Page")
                            .frame(width: 150, height: 100)
                    }
                    .position(x: UIScreen.main.bounds.width/24, y: UIScreen.main.bounds.height/1.14)
                }
                
                if currentPage < 3{
                    Button(action: {
                        if currentPage < numberOfPages - 1 {
                            currentPage += 1
                        }
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Next Button in Level Page")
                            .frame(width: 80, height: 50)
                    }
                    .disabled(currentPage >= numberOfPages - 1)
                    .position(x: UIScreen.main.bounds.width/1.14, y: UIScreen.main.bounds.height/1.17)
                }
                
                Button(action: {
                    withAnimation{
                        navigateToMenu = true
                        generateHapticFeedbackMedium()
                    }
                }) {
                    Image("Previous Button in Level Page")
                        .frame(width: 150, height: 100)
                }
                .position(x: UIScreen.main.bounds.width/24, y: UIScreen.main.bounds.height/4.2)
                
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
        }
    }
}



struct CircuitsView: View {
    @State private var navigateToWire = false
    @State private var navigateToAnd = false
    @State private var navigateToOr = false
    @State private var navigateToNor = false
    @State private var navigateToNand = false
    @State private var navigateToNot = false
    @State private var navigateToXor = false
    @State private var navigateToXnor = false
    @State private var navigateToMenu = false
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        ZStack {
            if languageEnabled {
                Image("COMPONENTS PAGE BACKGROUND CHINESE")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Image("COMPONENTS PAGE BACKGROUND")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
            }
            
                
            Button(action: {
                navigateToMenu = true
                generateHapticFeedbackMedium()
            }) {
                Image("Previous Button in Level Page")
            }
            .position(x: UIScreen.main.bounds.width/7.3, y: UIScreen.main.bounds.height/5.05)
            
                NavigationStack {
                    VStack(spacing: 10) {
                        HStack(spacing: 5) {
                            Button(action: {
                                navigateToWire = true
                                generateHapticFeedbackMedium()
                            }) {
                                if languageEnabled {
                                    Image("WIRE BUTTON Chinese")
                                } else {
                                    Image("WIRE BUTTON")
                                }
                            }
                            
                            Button(action: {
                                navigateToNot = true
                                generateHapticFeedbackMedium()
                            }) {
                                if languageEnabled {
                                    Image("NOT BUTTON Chinese")
                                } else {
                                    Image("NOT BUTTON")
                                }
                            }
                            
                            Button(action: {
                                navigateToAnd = true
                                generateHapticFeedbackMedium()
                            }) {
                                if languageEnabled {
                                    Image("AND BUTTON Chinese")
                                } else {
                                    Image("AND BUTTON")
                                }
                            }
                            
                            
                            Button(action: {
                                navigateToOr = true
                                generateHapticFeedbackMedium()
                            }) {
                                if languageEnabled {
                                    Image("OR BUTTON Chinese")
                                } else {
                                    Image("OR BUTTON")
                                }
                            }
                        }
                        
                        HStack(spacing: 5) {
                            Button(action: {
                                navigateToNand = true
                                generateHapticFeedbackMedium()
                            }) {
                                if languageEnabled {
                                    Image("NAND BUTTON Chinese")
                                } else {
                                    Image("NAND BUTTON")
                                }
                            }
                            
                            Button(action: {
                                navigateToNor = true
                                generateHapticFeedbackMedium()
                            }) {
                                if languageEnabled {
                                    Image("NOR BUTTON Chinese")
                                } else {
                                    Image("NOR BUTTON")
                                }
                            }
                            
                            Button(action: {
                                navigateToXor = true
                                generateHapticFeedbackMedium()
                            }) {
                                if languageEnabled {
                                    Image("XOR BUTTON Chinese")
                                } else {
                                    Image("XOR BUTTON")
                                }
                            }
                            
                            Button(action: {
                                navigateToXnor = true
                                generateHapticFeedbackMedium()
                            }) {
                                if languageEnabled {
                                    Image("XNOR BUTTON Chinese")
                                } else {
                                    Image("XNOR BUTTON")
                                }
                            }
                        }
                    }
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.55)
                    
                    
                    .navigationDestination(isPresented: $navigateToWire) {
                        WireView()
                    }
                    .navigationDestination(isPresented: $navigateToAnd) {
                        AndView()
                    }
                    .navigationDestination(isPresented: $navigateToOr) {
                        OrView()
                    }
                    .navigationDestination(isPresented: $navigateToNor) {
                        NorView()
                    }
                    .navigationDestination(isPresented: $navigateToNand) {
                        NandView()
                    }
                    .navigationDestination(isPresented: $navigateToNot) {
                        NotView()
                    }
                    .navigationDestination(isPresented: $navigateToXor) {
                        XorView()
                    }
                    .navigationDestination(isPresented: $navigateToXnor) {
                        XnorView()
                    }
                    .navigationDestination(isPresented: $navigateToMenu) {
                        MenuView()
                    }
                }
                .navigationBarHidden(true)
            }
        }
    }


struct NavigationPageView: View {
    var onBackToLevel: () -> Void
    var onNextLevel: () -> Void
    var onBackToComponent: () -> Void
    var onSettings: () -> Void
    var onPreviousToLevel: () -> Void
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        if languageEnabled {
            Image("Navigation Page Background Chinese")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                .edgesIgnoringSafeArea(.all)
        } else {
            Image("Navigation Page Background")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                .edgesIgnoringSafeArea(.all)
        }
        
        
        HStack(spacing: UIScreen.main.bounds.height / 6){
            Button(action: {
                generateHapticFeedbackMedium()
                onBackToComponent()
            }) {
                Image("Home Button")
                    .frame(width: UIScreen.main.bounds.height / 10.5, height: UIScreen.main.bounds.height / 10.5)
            }
            Button(action: {
                generateHapticFeedbackMedium()
                onPreviousToLevel()
            }) {
                Image("Back Button")
                    .frame(width: UIScreen.main.bounds.height / 10.5, height: UIScreen.main.bounds.height / 10.5)
            }
            Button(action: {
                generateHapticFeedbackMedium()
                onNextLevel()
            }) {
                Image("Resume Button")
                    .frame(width: UIScreen.main.bounds.height / 10.5, height: UIScreen.main.bounds.height / 10.5)
            }
            Button(action: {
                generateHapticFeedbackMedium()
                onBackToLevel()
            }) {
                Image("Retry Button")
                    .frame(width: UIScreen.main.bounds.height / 10.5, height: UIScreen.main.bounds.height / 10.5)
            }
            Button(action: {
                generateHapticFeedbackMedium()
                onSettings()
            }) {
                Image("Setting Button")
                    .frame(width: UIScreen.main.bounds.height / 10.5, height: UIScreen.main.bounds.height / 10.5)
            }
        }
        .position(x:UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/2)
    }
}

struct FailPageView: View {
    var onRetryLevel: () -> Void // 重试当前关卡
    var onBackToMenu: () -> Void // 返回菜单
    var onBackToComponent: () -> Void // 返回组件页面

    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        ZStack {
            // 切换语言版本显示不同背景
            if languageEnabled {
                Image("Fail page Chinese") // 失败页面中文版本背景
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width / 1.91, y: UIScreen.main.bounds.height / 1.84)
                    .frame(width: UIScreen.main.bounds.width * 1.03, height: UIScreen.main.bounds.height * 1.03)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Image("Fail page") // 失败页面英文版背景
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width / 1.91, y: UIScreen.main.bounds.height / 1.84)
                    .frame(width: UIScreen.main.bounds.width * 1.03, height: UIScreen.main.bounds.height * 1.03)
                    .edgesIgnoringSafeArea(.all)
            }

            // // 动画效果，可以类似 `LottieAnimationViewContainer` 的动画，也可以是其他失败动画
            // // 到时候可以设计一下
            // LottieAnimationViewContainer(filename: "FailAnimation")
            //     .frame(width: 700, height: 400)

            // 横向布局的按钮
            HStack(spacing: UIScreen.main.bounds.height / 25) {
                Button(action: {
                    generateHapticFeedbackMedium()
                    onBackToComponent() // 返回到组件页面的回调
                }) {
                    Image("Back Button In Fail Page")
                        .frame(width: UIScreen.main.bounds.width / 10, height: UIScreen.main.bounds.height / 10)
                }

                Button(action: {
                    generateHapticFeedbackMedium()
                    onRetryLevel() // 重试关卡的回调
                }) {
                    Image("Retry Button In Fail Page")
                        .frame(width: UIScreen.main.bounds.width / 10, height: UIScreen.main.bounds.height / 10)
                }

                Button(action: {
                    generateHapticFeedbackMedium()
                    onBackToMenu() // 返回主菜单的回调
                }) {
                    Image("Menu Button In Fail Page")
                        .frame(width: UIScreen.main.bounds.width / 10, height: UIScreen.main.bounds.height / 10)
                }
            }
            .position(x: UIScreen.main.bounds.width / 1.91, y: UIScreen.main.bounds.height / 1.35)
        }
    }
}



struct SettingsView: View {
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    @AppStorage("musicEnabled") var musicEnabled: Bool = true
    @State private var isFirstAppearLanguage = true
    @State private var isFirstAppearMusic = true
    @EnvironmentObject var levelManager: LevelManager // 引入全局的 LevelManager 实例

    let switchPositionLanguage = CGPoint(x: UIScreen.main.bounds.width / 1.55, y: UIScreen.main.bounds.height/2.4)
    let switchpositionMusic = CGPoint(x: UIScreen.main.bounds.width / 1.55, y: UIScreen.main.bounds.height/1.83)
    
    func generateHapticFeedbackMedium() {
           let generator = UIImpactFeedbackGenerator(style: .medium)
           generator.prepare()
           generator.impactOccurred()
       }

    var body: some View {
        NavigationStack {
            ZStack {
                if languageEnabled {
                    Image("Settings Background Chinese")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                        .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                        .edgesIgnoringSafeArea(.all)
                } else {
                    Image("Settings Background")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                        .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                        .edgesIgnoringSafeArea(.all)
                }
                
                if languageEnabled {
                    if isFirstAppearLanguage {
                        Image("Level Switch On3")
                            .frame(width:67, height:33.5)
                            .position(switchPositionLanguage)
                            .onTapGesture {
                                isFirstAppearLanguage = false
                                languageEnabled.toggle()
                                generateHapticFeedbackMedium()
                            }
                    } else if languageEnabled {
                        LottieAnimationViewContainer(filename: "Level Page Switch On3")
                            .frame(width: 67, height: 33.5)
                            .position(switchPositionLanguage)
                            .onTapGesture {
                                languageEnabled.toggle()
                                generateHapticFeedbackMedium()
                            }
                    } else {
                        LottieAnimationViewContainer(filename: "Level Page Switch Off3")
                            .frame(width: 67, height: 33.5)
                            .position(switchPositionLanguage)
                            .onTapGesture {
                                languageEnabled.toggle()
                                generateHapticFeedbackMedium()
                            }
                    }
                } else {
                    if isFirstAppearLanguage {
                        Image("Level Switch Off3")
                            .frame(width:67, height:33.5)
                            .position(switchPositionLanguage)
                            .onTapGesture {
                                isFirstAppearLanguage = false
                                languageEnabled.toggle()
                                generateHapticFeedbackMedium()
                            }
                    } else if languageEnabled {
                        LottieAnimationViewContainer(filename: "Level Page Switch On3")
                            .frame(width: 67, height: 33.5)
                            .position(switchPositionLanguage)
                            .onTapGesture {
                                languageEnabled.toggle()
                                generateHapticFeedbackMedium()
                            }
                    } else {
                        LottieAnimationViewContainer(filename: "Level Page Switch Off3")
                            .frame(width: 67, height: 33.5)
                            .position(switchPositionLanguage)
                            .onTapGesture {
                                languageEnabled.toggle()
                                generateHapticFeedbackMedium()
                            }
                    }
                }
                    
                VStack {
                    // 重置所有星星按钮
                    Button(action: {
                        levelManager.resetAllStars() // 调用 resetAllStars() 方法清除所有星星
                        generateHapticFeedbackMedium() // 添加触觉反馈
                    }) {
                        Text(languageEnabled ? "重置所有星星" : "Reset All Stars")
                            .font(.headline)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .position(x: UIScreen.main.bounds.width / 3.4, y: UIScreen.main.bounds.height/1.35)

                    // 音乐和语言设置的开关部分（保持不变）
                    if musicEnabled {
                        if isFirstAppearMusic {
                            Image("Level Switch On3")
                                .frame(width: 67, height: 33.5)
                                .position(switchpositionMusic)
                                .onTapGesture {
                                    isFirstAppearMusic = false
                                    musicEnabled.toggle()
                                    generateHapticFeedbackMedium()
                                }
                        } else if musicEnabled {
                            LottieAnimationViewContainer(filename: "Level Page Switch On3")
                                .frame(width: 67, height: 33.5)
                                .position(switchpositionMusic)
                                .onTapGesture {
                                    musicEnabled.toggle()
                                    generateHapticFeedbackMedium()
                                }
                        } else {
                            LottieAnimationViewContainer(filename: "Level Page Switch Off3")
                                .frame(width: 67, height: 33.5)
                                .position(switchpositionMusic)
                                .onTapGesture {
                                    musicEnabled.toggle()
                                    generateHapticFeedbackMedium()
                                }
                        }
                    } else {
                        if isFirstAppearMusic {
                            Image("Level Switch Off3")
                                .frame(width: 67, height: 33.5)
                                .position(switchpositionMusic)
                                .onTapGesture {
                                    isFirstAppearMusic = false
                                    musicEnabled.toggle()
                                    generateHapticFeedbackMedium()
                                }
                        } else if musicEnabled {
                            LottieAnimationViewContainer(filename: "Level Page Switch On3")
                                .frame(width: 67, height: 33.5)
                                .position(switchpositionMusic)
                                .onTapGesture {
                                    musicEnabled.toggle()
                                    generateHapticFeedbackMedium()
                                }
                        } else {
                            LottieAnimationViewContainer(filename: "Level Page Switch Off3")
                                .frame(width: 67, height: 33.5)
                                .position(switchpositionMusic)
                                .onTapGesture {
                                    musicEnabled.toggle()
                                    generateHapticFeedbackMedium()
                                }
                        }
                    }
                    
                    Spacer()
                    
                    // 社交媒体图标部分（保持不变）
                    HStack(spacing: 20) {
                        SocialMediaIcon(iconName: "social media linkedin", url: "https://www.linkedin.com/company/xor-education/?lipi=urn%3Ali%3Apage%3Acompanies_company_index%3B56d61717-8ed7-4141-9c20-ff714437af1c")
                        SocialMediaIcon(iconName: "social media instagram", url: "https://www.instagram.com/xor_computer_engineering?igsh=MWVkNW5yaWJqdjg5eA%3D%3D&utm_source=qr")
                        SocialMediaIcon(iconName: "social media xiaohongshu", url: "https://www.xiaohongshu.com/user/profile/6260567f000000001000a0f9?xhsshare=CopyLink&appuid=6260567f000000001000a0f9&apptime=1723020999&share_id=37834349426641f690bc24b01099a05b")
                        SocialMediaIcon(iconName: "social media tiktok", url: "https://imgur.com/a/5fCEKdt")
                        SocialMediaIcon(iconName: "social media youtube", url: "https://youtube.com/@xor_education?si=8HBF-5WTpshQbx9g")
                        SocialMediaIcon(iconName: "social media discord", url: "https://discord.gg/Mc9y6cfF")
                        SocialMediaIcon(iconName: "social media kuaishou", url: "https://v.kuaishou.com/PpqLa8")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 200)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// Component for social media icon
struct SocialMediaIcon: View {
    let iconName: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            Image(iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
        }
    }
}

struct WireView: View {
    @State private var isSwitchOn = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var navigateToAnd = false
    @State private var navigateToCircuitsView = false
    @State private var isFirstAppear = true
    @State private var infoAppear = false
    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    let wirePosition = CGPoint(x: UIScreen.main.bounds.width/1.82, y: UIScreen.main.bounds.height/1.76)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }

    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToCircuitsView = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Wire Wire Chinese")
                        .position(wirePosition)
                }
                else {
                    Image("Wire Wire")
                        .position(wirePosition)
                }
                
                Image("Bulb OFF")
                        .position(x: wirePosition.x+159, y: wirePosition.y-45)
                
                Image("Bulb ON")
                    .position(x: wirePosition.x+159, y: wirePosition.y-45)
                    .opacity(isSwitchOn ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitchOn)

                if isFirstAppear {
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(x: wirePosition.x-202, y: wirePosition.y-10)
                        .onTapGesture {
                            isFirstAppear = false
                            isSwitchOn.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else if isSwitchOn {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(x: wirePosition.x-202, y: wirePosition.y-10)
                        .onTapGesture {
                            isSwitchOn.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(x: wirePosition.x-202, y: wirePosition.y-10)
                        .onTapGesture {
                            isSwitchOn.toggle()
                            generateHapticFeedbackHeavy()
                        }
                }
                
                let InfoButtonPosition = CGPoint(x: 175, y: 64)
                
                Button(action: {
                    infoAppear = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("InfoButton")
                        .frame(width: 50, height: 50)
                }
                .position(InfoButtonPosition)
                
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                if infoAppear {
                    if languageEnabled {
                        Image("Info Screen For Wire Chinese")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    else {
                        Image("Info Screen For Wire")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    
                    Button(action: {
                        infoAppear = false
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Cancel Button")
                            .frame(width: 50, height: 50)
                    }
                    .position(x: InfoScreenPosition.x + 275, y: InfoScreenPosition.y - 125)
                }

                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitchOn = false
                            isFirstAppear = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToCircuitsView = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToCircuitsView) {
                CircuitsView()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}

struct NotView: View {
    @State private var isSwitchOn = false
    @State private var navigateToAndView = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var navigateToCircuitsView = false
    @State private var isFirstAppear = true
    @State private var infoAppear = false
    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/4, y: UIScreen.main.bounds.height/1.629)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToCircuitsView = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Not Wire Chinese")
                        .position(x: switchPosition.x + 267, y: switchPosition.y - 7)
                }
                else {
                    Image("Not Wire")
                        .position(x: switchPosition.x + 267, y: switchPosition.y - 7)
                }
                
                Image("Bulb OFF")
                        .position(x: switchPosition.x+483, y: switchPosition.y-33)
                
                Image("Bulb ON")
                    .position(x: switchPosition.x+483, y: switchPosition.y-33)
                    .opacity(isSwitchOn ? 0 : 1)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitchOn)

                if isFirstAppear {
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear = false
                            isSwitchOn.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else if isSwitchOn {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitchOn.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitchOn.toggle()
                            generateHapticFeedbackHeavy()
                        }
                }
                
                let InfoButtonPosition = CGPoint(x: 175, y: 64)
                
                Button(action: {
                    infoAppear = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("InfoButton")
                        .frame(width: 50, height: 50)
                }
                .position(InfoButtonPosition)
                
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                if infoAppear {
                    if languageEnabled {
                        Image("Info Screen For Not Chinese")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    else {
                        Image("Info Screen For Not")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    
                    Button(action: {
                        infoAppear = false
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Cancel Button")
                            .frame(width: 50, height: 50)
                    }
                    .position(x: InfoScreenPosition.x + 275, y: InfoScreenPosition.y - 125)
                }

                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitchOn = false
                            isFirstAppear = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToCircuitsView = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToCircuitsView) {
                CircuitsView()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}

struct AndView: View {
    @State private var isSwitch1On = false
    @State private var isSwitch2On = false
    @State private var navigateToAndView = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var navigateToCircuitsView = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var infoAppear = false
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/4.05, y: UIScreen.main.bounds.height/2.1)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width/4.05, y: UIScreen.main.bounds.height/2.1+90)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
            NavigationStack {
                ZStack {
                    Image("Main Page Background color")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                        .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                        .edgesIgnoringSafeArea(.all)
                    
                    let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                    
                    Button(action: {
                        navigateToCircuitsView = true
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Previous Button in Level Page")
                    }
                    .position(PreviousButtonPosition)
                    
                    if languageEnabled {
                        Image("And Wire Chinese")
                            .position(x: switchPosition.x + 277, y: switchPosition.y + 36)
                    }
                    else {
                        Image("And Wire")
                            .position(x: switchPosition.x + 277, y: switchPosition.y + 36)
                    }
                    
                    Image("Bulb OFF")
                        .position(x: switchPosition.x+499, y: switchPosition.y+9)
                    
                    Image("Bulb ON")
                        .position(x: switchPosition.x+499, y: switchPosition.y+9)
                        .opacity(isSwitch1On && isSwitch2On ? 1 : 0)
                        .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitch1On && isSwitch2On)
                    
                    if isFirstAppear1 {
                        Image("Level Switch Off")
                            .frame(width:124, height:62)
                            .position(switchPosition)
                            .onTapGesture {
                                isFirstAppear1 = false
                                isSwitch1On.toggle()
                                generateHapticFeedbackHeavy()
                            }
                    } else if isSwitch1On {
                        LottieAnimationViewContainer(filename: "Level Page Switch On")
                            .frame(width: 124, height: 62)
                            .position(switchPosition)
                            .onTapGesture {
                                isSwitch1On.toggle()
                                generateHapticFeedbackHeavy()
                            }
                    } else {
                        LottieAnimationViewContainer(filename: "Level Page Switch Off")
                            .frame(width: 124, height: 62)
                            .position(switchPosition)
                            .onTapGesture {
                                isSwitch1On.toggle()
                                generateHapticFeedbackHeavy()
                            }
                    }
                    
                    if isFirstAppear2 {
                        Image("Level Switch Off")
                            .frame(width:124, height:62)
                            .position(switchPosition2)
                            .onTapGesture {
                                isFirstAppear2 = false
                                isSwitch2On.toggle()
                                generateHapticFeedbackHeavy()
                            }
                    } else if isSwitch2On {
                        LottieAnimationViewContainer(filename: "Level Page Switch On")
                            .frame(width: 124, height: 62)
                            .position(switchPosition2)
                            .onTapGesture {
                                isSwitch2On.toggle()
                                generateHapticFeedbackHeavy()
                            }
                    } else {
                        LottieAnimationViewContainer(filename: "Level Page Switch Off")
                            .frame(width: 124, height: 62)
                            .position(switchPosition2)
                            .onTapGesture {
                                isSwitch2On.toggle()
                                generateHapticFeedbackHeavy()
                            }
                    }
                    
                    
                    let InfoButtonPosition = CGPoint(x: 175, y: 64)
                    
                    Button(action: {
                        infoAppear = true
                        generateHapticFeedbackMedium()
                    }) {
                        Image("InfoButton")
                            .frame(width: 50, height: 50)
                    }
                    .position(InfoButtonPosition)
                    
                    let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                    
                    if infoAppear {
                        if languageEnabled {
                            Image("Info Screen For And Chinese")
                                .frame(width: 600, height: 300)
                                .position(InfoScreenPosition)
                                .animation(Animation.easeIn(duration: 10), value: infoAppear)
                        }
                        else {
                            Image("Info Screen For And")
                                .frame(width: 600, height: 300)
                                .position(InfoScreenPosition)
                                .animation(Animation.easeIn(duration: 10), value: infoAppear)
                        }
                        
                        Button(action: {
                            infoAppear = false
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Cancel Button")
                                .frame(width: 50, height: 50)
                        }
                        .position(x: InfoScreenPosition.x + 275, y: InfoScreenPosition.y - 125)
                    }
                    
                    let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                    
                    Button(action: {
                        showNavigationPage = true
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Navigation")
                            .frame(width: 50, height: 50)
                    }
                    .position(navPosition)
                    
                    if showNavigationPage {
                        NavigationPageView(
                            onBackToLevel: {
                                showNavigationPage = false
                                isSwitch1On = false
                                isSwitch2On = false
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                            },
                            onNextLevel: {
                                showNavigationPage = false
                            },
                            onBackToComponent: {
                                showNavigationPage = false
                                navigateToMenu = true
                            },
                            onSettings: {
                                showNavigationPage = false
                                navigateToSettings = true
                            },
                            onPreviousToLevel: {
                                showNavigationPage = false
                                navigateToCircuitsView = true
                            }
                        )
                        .transition(.move(edge: .bottom))
                    }
                    if navigateToSettings {
                                        SettingsView()
                                        Button(action: {
                                            navigateToSettings = false
                                            generateHapticFeedbackMedium()
                                        }) {
                                            Image("Cancel Button")
                                                .frame(width: 50, height: 50)
                                        }
                                        .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                    }
                }
                .navigationDestination(isPresented: $navigateToCircuitsView) {
                    CircuitsView()
                }
                .navigationDestination(isPresented: $navigateToMenu) {
                    MenuView()
                }
            }
            .navigationBarHidden(true)
        }
    }

struct OrView: View {
    @State private var isSwitch1On = false
    @State private var isSwitch2On = false
    @State private var navigateToAndView = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var navigateToCircuitsView = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var infoAppear = false
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/4.03, y: UIScreen.main.bounds.height/2.1)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width/4.03, y: UIScreen.main.bounds.height/2.1+90)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToCircuitsView = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Or Wire Chinese")
                        .position(x: switchPosition.x + 275, y: switchPosition.y + 36)
                }
                else {
                    Image("Or Wire")
                        .position(x: switchPosition.x + 275, y: switchPosition.y + 36)
                }
                
                Image("Bulb OFF")
                    .position(x: switchPosition.x+484, y: switchPosition.y+9)
                
                Image("Bulb ON")
                    .position(x: switchPosition.x+484, y: switchPosition.y+9)
                    .opacity(isSwitch1On || isSwitch2On ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitch1On || isSwitch2On)
                
                if isFirstAppear1 {
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                }
                
                if isFirstAppear2 {
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                }
                
                
                let InfoButtonPosition = CGPoint(x: 175, y: 64)
                
                Button(action: {
                    infoAppear = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("InfoButton")
                        .frame(width: 50, height: 50)
                }
                .position(InfoButtonPosition)
                
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                if infoAppear {
                    if languageEnabled {
                        Image("Info Screen For Or Chinese")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    else {
                        Image("Info Screen For Or")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }

                    Button(action: {
                        infoAppear = false
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Cancel Button")
                            .frame(width: 50, height: 50)
                    }
                    .position(x: InfoScreenPosition.x + 275, y: InfoScreenPosition.y - 125)
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                Button(action: {
                    showNavigationPage = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Navigation")
                        .frame(width: 50, height: 50)
                }
                .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = false
                            isSwitch2On = false
                            isFirstAppear1 = true
                            isFirstAppear2 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToCircuitsView = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToCircuitsView) {
                CircuitsView()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
        }
        .navigationBarHidden(true)
    }
}

struct NandView: View {
    @State private var isSwitch1On = false
    @State private var isSwitch2On = false
    @State private var navigateToAndView = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var navigateToCircuitsView = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var infoAppear = false
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/4.03, y: UIScreen.main.bounds.height/2.1)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width/4.03, y: UIScreen.main.bounds.height/2.1+90)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToCircuitsView = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Nand Wire Chinese")
                        .position(x: switchPosition.x + 277, y: switchPosition.y + 35)
                }
                else {
                    Image("Nand Wire")
                        .position(x: switchPosition.x + 277, y: switchPosition.y + 35)
                }
                
                Image("Bulb OFF")
                    .position(x: switchPosition.x+499, y: switchPosition.y+8)
                
                Image("Bulb ON")
                    .position(x: switchPosition.x+499, y: switchPosition.y+8)
                    .opacity(!(isSwitch1On && isSwitch2On) ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: !(isSwitch1On && isSwitch2On))
                
                if isFirstAppear1 {
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                }
                
                if isFirstAppear2 {
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                }
                
                
                let InfoButtonPosition = CGPoint(x: 175, y: 64)
                
                Button(action: {
                    infoAppear = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("InfoButton")
                        .frame(width: 50, height: 50)
                }
                .position(InfoButtonPosition)
                
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                if infoAppear {
                    if languageEnabled {
                        Image("Info Screen For Nand Chinese")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    else {
                        Image("Info Screen For Nand")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }

                    Button(action: {
                        infoAppear = false
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Cancel Button")
                            .frame(width: 50, height: 50)
                    }
                    .position(x: InfoScreenPosition.x + 275, y: InfoScreenPosition.y - 125)
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                Button(action: {
                    showNavigationPage = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Navigation")
                        .frame(width: 50, height: 50)
                }
                .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = false
                            isSwitch2On = false
                            isFirstAppear1 = true
                            isFirstAppear2 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToCircuitsView = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToCircuitsView) {
                CircuitsView()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
        }
        .navigationBarHidden(true)
    }
}

struct NorView: View {
    @State private var isSwitch1On = false
    @State private var isSwitch2On = false
    @State private var navigateToAndView = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var navigateToCircuitsView = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var infoAppear = false
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/4.03, y: UIScreen.main.bounds.height/2.1)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width/4.03, y: UIScreen.main.bounds.height/2.1+90)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToCircuitsView = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                if languageEnabled {
                    Image("Nor Wire Chinese")
                        .position(x: switchPosition.x + 277, y: switchPosition.y + 36)
                }
                else {
                    Image("Nor Wire")
                        .position(x: switchPosition.x + 277, y: switchPosition.y + 36)
                }
                
                Image("Bulb OFF")
                    .position(x: switchPosition.x+499, y: switchPosition.y+9)
                
                Image("Bulb ON")
                    .position(x: switchPosition.x+499, y: switchPosition.y+9)
                    .opacity(!(isSwitch1On || isSwitch2On) ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: !(isSwitch1On || isSwitch2On))
                
                if isFirstAppear1 {
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                }
                
                if isFirstAppear2 {
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                }
                
                
                let InfoButtonPosition = CGPoint(x: 175, y: 64)
                
                Button(action: {
                    infoAppear = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("InfoButton")
                        .frame(width: 50, height: 50)
                }
                .position(InfoButtonPosition)
                
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                if infoAppear {
                    if languageEnabled {
                        Image("Info Screen For Nor Chinese")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    else {
                        Image("Info Screen For Nor")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    
                    Button(action: {
                        infoAppear = false
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Cancel Button")
                            .frame(width: 50, height: 50)
                    }
                    .position(x: InfoScreenPosition.x + 275, y: InfoScreenPosition.y - 125)
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                Button(action: {
                    showNavigationPage = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Navigation")
                        .frame(width: 50, height: 50)
                }
                .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = false
                            isSwitch2On = false
                            isFirstAppear1 = true
                            isFirstAppear2 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToCircuitsView = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToCircuitsView) {
                CircuitsView()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
        }
        .navigationBarHidden(true)
    }
}


struct XorView: View {
    @State private var isSwitch1On = false
    @State private var isSwitch2On = false
    @State private var navigateToAndView = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var navigateToCircuitsView = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var infoAppear = false
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/4.03, y: UIScreen.main.bounds.height/2.1)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width/4.03, y: UIScreen.main.bounds.height/2.1+90)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToCircuitsView = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                if languageEnabled {
                    Image("Xor Wire Chinese")
                        .position(x: switchPosition.x + 275, y: switchPosition.y + 36)
                }
                else {
                    Image("Xor Wire")
                        .position(x: switchPosition.x + 275, y: switchPosition.y + 36)
                }
                
                Image("Bulb OFF")
                    .position(x: switchPosition.x+483, y: switchPosition.y+9)
                
                Image("Bulb ON")
                    .position(x: switchPosition.x+483, y: switchPosition.y+9)
                    .opacity((isSwitch1On != isSwitch2On) ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: (isSwitch1On != isSwitch2On))
                
                if isFirstAppear1 {
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                }
                
                if isFirstAppear2 {
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                }
                
                
                let InfoButtonPosition = CGPoint(x: 175, y: 64)
                
                Button(action: {
                    infoAppear = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("InfoButton")
                        .frame(width: 50, height: 50)
                }
                .position(InfoButtonPosition)
                
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                if infoAppear {
                    if languageEnabled {
                        Image("Info Screen For Xor Chinese")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    else {
                        Image("Info Screen For Xor")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    
                    Button(action: {
                        infoAppear = false
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Cancel Button")
                            .frame(width: 50, height: 50)
                    }
                    .position(x: InfoScreenPosition.x + 275, y: InfoScreenPosition.y - 125)
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                Button(action: {
                    showNavigationPage = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Navigation")
                        .frame(width: 50, height: 50)
                }
                .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = false
                            isSwitch2On = false
                            isFirstAppear1 = true
                            isFirstAppear2 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToCircuitsView = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToCircuitsView) {
                CircuitsView()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
        }
        .navigationBarHidden(true)
    }
}

struct XnorView: View {
    @State private var isSwitch1On = false
    @State private var isSwitch2On = false
    @State private var navigateToAndView = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var navigateToCircuitsView = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var infoAppear = false
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/4.03, y: UIScreen.main.bounds.height/2.1)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width/4.03, y: UIScreen.main.bounds.height/2.1+90)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToCircuitsView = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Xnor Wire Chinese")
                        .position(x: switchPosition.x + 277, y: switchPosition.y + 36)
                }
                else {
                    Image("Xnor Wire")
                        .position(x: switchPosition.x + 277, y: switchPosition.y + 36)
                }
                
                Image("Bulb OFF")
                    .position(x: switchPosition.x+497, y: switchPosition.y+9)
                
                Image("Bulb ON")
                    .position(x: switchPosition.x+497, y: switchPosition.y+9)
                    .opacity((isSwitch1On == isSwitch2On) ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: (isSwitch1On == isSwitch2On))
                
                if isFirstAppear1 {
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                }
                
                if isFirstAppear2 {
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                        }
                }
                
                
                let InfoButtonPosition = CGPoint(x: 175, y: 64)
                
                Button(action: {
                    infoAppear = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("InfoButton")
                        .frame(width: 50, height: 50)
                }
                .position(InfoButtonPosition)
                
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                if infoAppear {
                    if languageEnabled {
                        Image("Info Screen For Xnor Chinese")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    else {
                        Image("Info Screen For Xnor")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    
                    Button(action: {
                        infoAppear = false
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Cancel Button")
                            .frame(width: 50, height: 50)
                    }
                    .position(x: InfoScreenPosition.x + 275, y: InfoScreenPosition.y - 125)
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                Button(action: {
                    showNavigationPage = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Navigation")
                        .frame(width: 50, height: 50)
                }
                .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = false
                            isSwitch2On = false
                            isFirstAppear1 = true
                            isFirstAppear2 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToCircuitsView = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToCircuitsView) {
                CircuitsView()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
        }
        .navigationBarHidden(true)
    }
}
struct LevelView: View {
    let level: Int
    
    var body: some View {
        switch level {
        case 1:
            Level1View()
        case 2:
            Level2View()
        case 3:
            Level3View()
        case 4:
            Level4View()
        case 5:
            Level5View()
        case 6:
            Level6View()
        case 7:
            Level7View()
        case 8:
            Level8View()
        case 9:
            Level9View()
        case 10:
            Level10View()
        case 11:
            Level11View()
        case 12:
            Level12View()
        case 13:
            Level13View()
        case 14:
            Level14View()
        case 15:
            Level15View()
        case 16:
            Level16View()
        case 17:
            Level17View()
        case 18:
            Level18View()
        case 19:
            Level19View()
        case 20:
            Level20View()
        case 21:
            Level21View()
        case 22:
            Level22View()
        case 23:
            Level23View()
        case 24:
            Level24View()
        case 25:
            Level25View()
        case 26:
            Level26View()
        case 27:
            Level27View()
        case 28:
            Level28View()
        case 29:
            Level29View()
        case 30:
            Level30View()
        case 31:
            Level31View()
        default:
            DefaultLevelView(level: level)
        }
    }
}

struct Level1View: View {
    @State private var isSwitchOn = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel2 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear = true
    @State private var infoAppear = false
    @State private var isInteractionEnabled = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/3.355, y: UIScreen.main.bounds.height/1.829)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level1 Wire Chinese")
                        .position(x: switchPosition.x + 214, y: switchPosition.y + 30)
                } else {
                    Image("Level1 Wire")
                        .position(x: switchPosition.x + 214, y: switchPosition.y + 30)
                }
                
                Image("Bulb OFF")
                        .position(x: switchPosition.x+375, y: switchPosition.y-33)
                
                Image("Bulb ON")
                    .position(x: switchPosition.x+375, y: switchPosition.y-33)
                    .opacity(isSwitchOn ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitchOn)
                
                
                if isFirstAppear{
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(x: switchPosition.x, y: switchPosition.y)
                        .onTapGesture {
                            isFirstAppear = false
                            isSwitchOn = true
                            generateHapticFeedbackHeavy()
                            if isSwitchOn {
                                isInteractionEnabled = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled = true
                                    }
                                }
                            }
                        }
                }
                else if isSwitchOn {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitchOn.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitchOn {
                                isInteractionEnabled = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled = true
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitchOn.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitchOn {
                                isInteractionEnabled = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled)
                }
                
                let InfoButtonPosition = CGPoint(x: 175, y: 64)
                
                Button(action: {
                    infoAppear = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("InfoButton")
                        .frame(width: 50, height: 50)
                }
                .position(InfoButtonPosition)
                
                if infoAppear {
                    if languageEnabled {
                        Image("Info Screen For Wire Chinese")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    else {
                        Image("Info Screen For Wire")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    
                    Button(action: {
                        infoAppear = false
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Cancel Button")
                            .frame(width: 50, height: 50)
                    }
                    .position(x: InfoScreenPosition.x + 275, y: InfoScreenPosition.y - 125)
                }
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitchOn = false
                                isFirstAppear = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel2 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation {
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitchOn = false
                            isFirstAppear = true
                            isInteractionEnabled = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel2) {
                Level2View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}

struct Level2View: View {
    @State private var isSwitchOn = true
    @State private var showFinishedPage = false
    @State private var navigateToLevel3 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear = true
    @State private var isInteractionEnabled = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/3.37, y: UIScreen.main.bounds.height/1.829)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        NavigationStack {
            ZStack{
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
            
            if languageEnabled {
                Image("Level2 Wire Chinese")
                    .position(x: switchPosition.x + 215, y: switchPosition.y + 45)
            } else {
                Image("Level2 Wire")
                    .position(x: switchPosition.x + 215, y: switchPosition.y + 45)
            }
            
            Image("Bulb OFF")
                    .position(x: switchPosition.x+377, y: switchPosition.y-33)
            
            Image("Bulb ON")
                .position(x: switchPosition.x+377, y: switchPosition.y-33)
                .opacity(isSwitchOn ? 1 : 0)
                .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitchOn)
            
            
            if isFirstAppear{
                Image("Level Switch On")
                    .frame(width:124, height:62)
                    .position(x: switchPosition.x, y: switchPosition.y)
                    .onTapGesture {
                        isFirstAppear = false
                        isSwitchOn.toggle()
                        generateHapticFeedbackHeavy()
                        if !isSwitchOn {
                            isInteractionEnabled = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation {
                                    showFinishedPage = true
                                    isInteractionEnabled = true
                                }
                            }
                        }
                    }
            }
            else if isSwitchOn {
                LottieAnimationViewContainer(filename: "Level Page Switch On")
                    .frame(width: 124, height: 62)
                    .position(switchPosition)
                    .onTapGesture {
                        isSwitchOn.toggle()
                        generateHapticFeedbackHeavy()
                        if !isSwitchOn {
                            isInteractionEnabled = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation {
                                    showFinishedPage = true
                                    isInteractionEnabled = true
                                }
                            }
                        }
                        
                    }
                    .disabled(!isInteractionEnabled)
            } else {
                LottieAnimationViewContainer(filename: "Level Page Switch Off")
                    .frame(width: 124, height: 62)
                    .position(switchPosition)
                    .onTapGesture {
                        isSwitchOn.toggle()
                        generateHapticFeedbackHeavy()
                        if !isSwitchOn {
                            isInteractionEnabled = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation {
                                    showFinishedPage = true
                                    isInteractionEnabled = true
                                }
                            }
                        }
                    }
                    .disabled(!isInteractionEnabled)
            }
            
            if showFinishedPage {
                FinishedPageView(
                    onBackToLevel: {
                        withAnimation {
                            showFinishedPage = false
                            isSwitchOn = true
                            isFirstAppear = true
                        }
                    },
                    onNextLevel: {
                        withAnimation {
                            navigateToLevel3 = true
                        }
                    },
                    onBackToComponent: {
                        withAnimation {
                            navigateToComponent = true
                        }
                    }
                )
                .transition(.move(edge: .bottom))
            }
            
            let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
            Button(action: {
                    showNavigationPage = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Navigation")
                        .frame(width: 50, height: 50)
            }
            .position(navPosition)
                
                
            let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
            if showNavigationPage {
                NavigationPageView(
                    onBackToLevel: {
                        showNavigationPage = false
                        navigateToLevel3 = true
                        isSwitchOn = true
                        isInteractionEnabled = true
                    },
                    onNextLevel: {
                        showNavigationPage = false
                    },
                    onBackToComponent: {
                        showNavigationPage = false
                        navigateToMenu = true
                    },
                    onSettings: {
                        showNavigationPage = false
                        navigateToSettings = true
                    },
                    onPreviousToLevel: {
                        showNavigationPage = false
                        navigateToComponent = true
                    }
                )
                .transition(.move(edge: .bottom))
            }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
        }
        .navigationDestination(isPresented: $navigateToComponent) {
            ComponentsView()
        }
        .navigationDestination(isPresented: $navigateToLevel3) {
            Level3View()
        }
        .navigationDestination(isPresented: $navigateToMenu) {
            MenuView()
        }
        }
        .navigationBarHidden(true)
    }
}

struct Level3View: View {
    @State private var isSwitchOn = true
    @State private var showFinishedPage = false
    @State private var navigateToLevel4 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear = true
    @State private var infoAppear = false
    @State private var isInteractionEnabled = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/4.27, y: UIScreen.main.bounds.height/1.829)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level3 Wire Chinese")
                        .position(x: switchPosition.x + 272, y: switchPosition.y-5)
                } else {
                    Image("Level3 Wire")
                        .position(x: switchPosition.x + 272, y: switchPosition.y-5)
                }
                
                Image("Bulb OFF")
                        .position(x: switchPosition.x+490, y: switchPosition.y-30)
                
                Image("Bulb ON")
                    .position(x: switchPosition.x+490, y: switchPosition.y-30)
                    .opacity(isSwitchOn ? 0 : 1)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitchOn)
                
                
                if isFirstAppear{
                    Image("Level Switch On")
                        .frame(width:124, height:62)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear = false
                            isSwitchOn.toggle()
                            generateHapticFeedbackHeavy()
                            if !isSwitchOn {
                                isInteractionEnabled = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled = true
                                    }
                                }
                            }
                        }
                }
                else if isSwitchOn {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitchOn.toggle()
                            generateHapticFeedbackHeavy()
                            if !isSwitchOn {
                                isInteractionEnabled = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitchOn.toggle()
                            generateHapticFeedbackHeavy()
                            if !isSwitchOn {
                                isInteractionEnabled = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled)
                }
                
                let InfoButtonPosition = CGPoint(x: 175, y: 64)
                
                Button(action: {
                    infoAppear = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("InfoButton")
                        .frame(width: 50, height: 50)
                }
                .position(InfoButtonPosition)
                
                if infoAppear {
                    if languageEnabled {
                        Image("Info Screen For Not Chinese")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    else {
                        Image("Info Screen For Not")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    
                    Button(action: {
                        infoAppear = false
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Cancel Button")
                            .frame(width: 50, height: 50)
                    }
                    .position(x: InfoScreenPosition.x + 275, y: InfoScreenPosition.y - 125)
                }
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitchOn = true
                                isFirstAppear = true
                                isInteractionEnabled = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel4 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation {
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitchOn = false
                            isFirstAppear = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel4) {
                Level4View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}

struct Level4View: View {
    @State private var isSwitchOn = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel5 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear = true
    @State private var isInteractionEnabled = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/4.27, y: UIScreen.main.bounds.height/1.829)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level4 Wire Chinese")
                        .position(x: switchPosition.x + 272, y: switchPosition.y+12)
                } else {
                    Image("Level4 Wire")
                        .position(x: switchPosition.x + 272, y: switchPosition.y+12)
                }

                Image("Bulb OFF")
                        .position(x: switchPosition.x+490, y: switchPosition.y-30)
                
                Image("Bulb ON")
                    .position(x: switchPosition.x+490, y: switchPosition.y-30)
                    .opacity(isSwitchOn ? 0 : 1)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitchOn)
                
                
                if isFirstAppear{
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear = false
                            isSwitchOn.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitchOn {
                                isInteractionEnabled = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled = true
                                    }
                                }
                            }
                        }
                }
                else if isSwitchOn {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitchOn.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitchOn {
                                isInteractionEnabled = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled = true
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitchOn.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitchOn {
                                isInteractionEnabled = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled)
                }
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitchOn = false
                                isFirstAppear = true
                                isInteractionEnabled = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel5 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation {
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitchOn = false
                            isFirstAppear = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel5) {
                Level5View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}

struct Level5View: View {
    @State private var isSwitchOn = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel6 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear = true
    @State private var isInteractionEnabled = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/4.30, y: UIScreen.main.bounds.height/1.829)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level5 Wire Chinese")
                        .position(x: switchPosition.x + 279, y: switchPosition.y-20)
                } else {
                    Image("Level5 Wire")
                        .position(x: switchPosition.x + 279, y: switchPosition.y-20)
                }
                
                Image("Bulb OFF")
                        .position(x: switchPosition.x+522, y: switchPosition.y-30)
                
                Image("Bulb ON")
                    .position(x: switchPosition.x+522, y: switchPosition.y-30)
                    .opacity(isSwitchOn ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitchOn)
                
                
                if isFirstAppear{
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear = false
                            isSwitchOn.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitchOn {
                                isInteractionEnabled = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitchOn {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitchOn.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitchOn {
                                isInteractionEnabled = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitchOn.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitchOn {
                                isInteractionEnabled = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled)
                }
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitchOn = false
                                isFirstAppear = false
                                isInteractionEnabled = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel6 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation {
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitchOn = false
                            isFirstAppear = false
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel6) {
                Level6View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}

struct Level6View: View {
    @State private var isSwitch1On = false
    @State private var isSwitch2On = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel7 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var infoAppear = false
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @State private var progress: CGFloat = 0.0 // 倒计时进度
    @EnvironmentObject var levelManager: LevelManager // 引入全局的 LevelManager

    // 新增状态变量，用于跟踪步数和最大步数
    @State private var currentSteps = 0
    let maxSteps = Int(pow(2.0, 2.0)) // 2^2 = 4 步
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect() // 定时器

    // 新增失败页面状态变量
    @State private var showFailedPage = false

    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    let switchPosition = CGPoint(x: UIScreen.main.bounds.width / 4.10, y: UIScreen.main.bounds.height/2.2)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width / 4.10, y: UIScreen.main.bounds.height/2.2+90)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    // 添加一个检查是否通关的函数
    func checkWinCondition() {
        if currentSteps <= maxSteps && isSwitch1On && isSwitch2On {
            isInteractionEnabled1 = false
            isInteractionEnabled2 = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    levelManager.markLevelAsCompleted(level: 6) // 标记关卡为已完成
                    showFinishedPage = true
                    isInteractionEnabled1 = false
                    isInteractionEnabled2 = false
                }
            }
        }
    }


    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width / 1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width / 1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level6 Wire Chinese")
                        .position(x: switchPosition.x + 268, y: switchPosition.y+52)
                } else {
                    Image("Level6 Wire")
                        .position(x: switchPosition.x + 268, y: switchPosition.y+52)
                }
                
                Image("Bulb OFF")
                        .position(x: switchPosition.x+491, y: switchPosition.y+4)
                
                Image("Bulb ON")
                    .position(x: switchPosition.x+491, y: switchPosition.y+4)
                    .opacity(isSwitch1On && isSwitch2On ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitch1On && isSwitch2On)
                
                
                // 添加一个进度条当作计时器 ------------------
                    // time out bar
                Rectangle()
                    .frame(width: 300, height: 20)
                    .foregroundColor(.red)
                    .position(x: UIScreen.main.bounds.width / 1.92, y: UIScreen.main.bounds.height/7)
                    // time start bar
                Rectangle()
                    .frame(width: 300 * progress, height: 20)
                    .foregroundColor(.gray)
                    .animation(.easeInOut, value: progress)
                    .position(x: UIScreen.main.bounds.width / 1.92 + 150 - 150*progress, y: UIScreen.main.bounds.height/7)
                    // -------------------------------------
                
                // 添加一个信息显示，提示剩余的步数
                Text("Steps Left: \(maxSteps - currentSteps)")
                    .font(.title)
                    .foregroundColor(.white)
                    .position(x: UIScreen.main.bounds.width / 1.92, y: UIScreen.main.bounds.height/7)
                // -----------------------------------------------
                
                if isFirstAppear1{
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition)
                        .onTapGesture { //这里有改动
                            isFirstAppear1 = false
                            if currentSteps < maxSteps {
                                isSwitch1On.toggle()
                                currentSteps += 1 // 每次操作步数+1
                                generateHapticFeedbackHeavy()
                                checkWinCondition() // 检查是否过关
                            }

                            else{
                                showFailedPage = true
                            }
                        }
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture { //这里有改动
                            if currentSteps < maxSteps {
                                isSwitch1On.toggle()
                                currentSteps += 1 // 每次操作步数+1
                                generateHapticFeedbackHeavy()
                                checkWinCondition() // 检查是否过关
                            }

                            else{
                                showFailedPage = true
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture { //这里有改动
                            if currentSteps < maxSteps {
                                isSwitch1On.toggle()
                                currentSteps += 1 // 每次操作步数+1
                                generateHapticFeedbackHeavy()
                                checkWinCondition() // 检查是否过关
                            }

                            else{
                                showFailedPage = true
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if isFirstAppear2{
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition2)
                        .onTapGesture { //这里有改动
                            isFirstAppear2 = false
                            if currentSteps < maxSteps {
                                isSwitch2On.toggle()
                                currentSteps += 1 // 每次操作步数+1
                                generateHapticFeedbackHeavy()
                                checkWinCondition() // 检查是否过关
                            }

                            else{
                                showFailedPage = true
                            }
                        }
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture { //这里有改动
                            if currentSteps < maxSteps {
                                isSwitch2On.toggle()
                                currentSteps += 1 // 每次操作步数+1
                                generateHapticFeedbackHeavy()
                                checkWinCondition() // 检查是否过关
                            }

                            else{
                                showFailedPage = true
                            }
                            
                        }
                        .disabled(!isInteractionEnabled2)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture { //这里有改动
                            if currentSteps < maxSteps {
                                isSwitch2On.toggle()
                                currentSteps += 1 // 每次操作步数+1
                                generateHapticFeedbackHeavy()
                                checkWinCondition() // 检查是否过关
                            }

                            else{
                                showFailedPage = true
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                

                let InfoButtonPosition = CGPoint(x: 175, y: 64)
                
                Button(action: {
                    infoAppear = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("InfoButton")
                        .frame(width: 50, height: 50)
                }
                .position(InfoButtonPosition)
                
                if infoAppear {
                    if languageEnabled {
                        Image("Info Screen For And Chinese")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    else {
                        Image("Info Screen For And")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                        
                    Button(action: {
                        infoAppear = false
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Cancel Button")
                            .frame(width: 50, height: 50)
                    }
                    .position(x: InfoScreenPosition.x + 275, y: InfoScreenPosition.y - 125)
                }
                
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = false
                                isSwitch2On = false
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                                currentSteps = 0
                                progress = 0
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel7 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation {
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }

                if showFailedPage {
                    FailPageView(
                        onRetryLevel: {
                            withAnimation {
                                showFailedPage = false
                                isSwitch1On = false
                                isSwitch2On = false
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                                currentSteps = 0 // 重置步数
                                progress = 0
                            }
                        },
                        onBackToMenu: {
                            withAnimation {
                                navigateToMenu = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation {
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }

                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = false
                            isSwitch2On = false
                            isFirstAppear1 = false
                            isFirstAppear2 = false
                            isInteractionEnabled1 = true
                            isInteractionEnabled2 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            // ------------------------------------------
            .onReceive(timer) { _ in
                // 每次定时器触发，更新进度
                if showFinishedPage == false{
                    progress += 0.01
                }
                if progress >= 1.0 {
                    // 如果进度达到 1.0，表示时间到，游戏失败
                    showFailedPage = true
                }
            }
            // ------------------------------------------
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel7) {
                Level7View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}


struct Level7View: View {
    @State private var isSwitch1On = false
    @State private var isSwitch2On = false
    @State private var isSwitch3On = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel8 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var navigateToMenu = false
    @State private var showNavigationPage = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isFirstAppear3 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @State private var isInteractionEnabled3 = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    let switch1Position = CGPoint(x: UIScreen.main.bounds.width/4.7, y: UIScreen.main.bounds.height/2.5)
    let switch2Position = CGPoint(x: UIScreen.main.bounds.width/4.7, y: UIScreen.main.bounds.height/2.5+66)
    let switch3Position = CGPoint(x: UIScreen.main.bounds.width/4.7+207, y: UIScreen.main.bounds.height/2.5+164)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level7 Wire Chinese")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 610, height: 305)
                        .position(x: switch1Position.x + 337.5, y: switch1Position.y + 88)
                }
                else {
                    Image("Level7 Wire")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 610, height: 305)
                        .position(x: switch1Position.x + 337.5, y: switch1Position.y + 88)
                }
                
                Image("Bulb OFF")
                    .position(x: switch1Position.x+584.7, y: switch1Position.y+63)
                    .opacity(isSwitch1On && isSwitch2On && isSwitch3On ? 0 : 1)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitch1On && isSwitch2On && isSwitch3On)
                
                
                Image("Bulb ON")
                    .position(x: switch1Position.x+584.7, y: switch1Position.y+63)
                    .opacity(isSwitch1On && isSwitch2On && isSwitch3On ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitch1On && isSwitch2On && isSwitch3On)
                
                if isFirstAppear1{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On && isSwitch3On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On && isSwitch3On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On && isSwitch3On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if isFirstAppear2{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On && isSwitch3On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On && isSwitch3On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On && isSwitch3On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                
                if isFirstAppear3{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch3Position)
                        .onTapGesture {
                            isFirstAppear3 = false
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On && isSwitch3On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                }
                else if isSwitch3On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch3Position)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On && isSwitch3On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch3Position)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On && isSwitch3On{
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                }
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = false
                                isSwitch2On = false
                                isSwitch3On = false
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isFirstAppear3 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                                isInteractionEnabled3 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel8 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation{
                                navigateToComponent = true
                            }
                        }
                    )
                    
                    .transition(.move(edge: .bottom))
                    
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                Button(action: {
                    showNavigationPage = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Navigation")
                        .frame(width: 50, height: 50)
                }
                .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = false
                            isSwitch2On = false
                            isSwitch3On = false
                            isFirstAppear1 = true
                            isFirstAppear2 = true
                            isFirstAppear3 = true
                            isInteractionEnabled1 = true
                            isInteractionEnabled2 = true
                            isInteractionEnabled3 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel8) {
                Level8View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
        }
        .navigationBarHidden(true)
    }
}

struct Level8View: View {
    @State private var isSwitch1On = false
    @State private var isSwitch2On = false
    @State private var isSwitch3On = false
    @State private var isSwitch4On = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel9 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var navigateToMenu = false
    @State private var showNavigationPage = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isFirstAppear3 = true
    @State private var isFirstAppear4 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @State private var isInteractionEnabled3 = true
    @State private var isInteractionEnabled4 = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    let switch1Position = CGPoint(x: UIScreen.main.bounds.width/4.7, y: UIScreen.main.bounds.height/2.8)
    let switch2Position = CGPoint(x: UIScreen.main.bounds.width/4.7, y: UIScreen.main.bounds.height/2.8+54)
    let switch3Position = CGPoint(x: UIScreen.main.bounds.width/4.7, y: UIScreen.main.bounds.height/2.8+133)
    let switch4Position = CGPoint(x: UIScreen.main.bounds.width/4.7, y: UIScreen.main.bounds.height/2.8+187)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level8 Wire Chinese")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 610, height: 305)
                        .position(x: switch1Position.x + 347, y: switch1Position.y + 106.5)
                }
                else {
                    Image("Level8 Wire")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 610, height: 305)
                        .position(x: switch1Position.x + 347, y: switch1Position.y + 106.5)
                }
                
                Image("Bulb OFF")
                    .position(x: switch1Position.x+573.6, y: switch1Position.y+59)
                    .opacity(isSwitch1On && isSwitch2On && isSwitch3On && isSwitch4On ? 0 : 1)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitch1On && isSwitch2On && isSwitch3On && isSwitch4On)
                
                
                Image("Bulb ON")
                    .position(x: switch1Position.x+573.6, y: switch1Position.y+59)
                    .opacity(isSwitch1On && isSwitch2On && isSwitch3On && isSwitch4On ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitch1On && isSwitch2On && isSwitch3On && isSwitch4On)
                
                if isFirstAppear1{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On && isSwitch3On && isSwitch4On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On && isSwitch3On && isSwitch4On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On && isSwitch3On && isSwitch4On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if isFirstAppear2{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On && isSwitch3On && isSwitch4On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On && isSwitch3On && isSwitch4On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On && isSwitch3On && isSwitch4On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                
                if isFirstAppear3{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch3Position)
                        .onTapGesture {
                            isFirstAppear3 = false
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On && isSwitch3On && isSwitch4On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                }
                else if isSwitch3On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch3Position)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On && isSwitch3On && isSwitch4On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch3Position)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On && isSwitch3On && isSwitch4On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                }
                
                if isFirstAppear4{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch4Position)
                        .onTapGesture {
                            isFirstAppear4 = false
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On && isSwitch3On && isSwitch4On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                }
                else if isSwitch4On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch4Position)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On && isSwitch3On && isSwitch4On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch4Position)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On && isSwitch3On && isSwitch4On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                }
                
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = false
                                isSwitch2On = false
                                isSwitch3On = false
                                isSwitch4On = false
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isFirstAppear3 = true
                                isFirstAppear4 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                                isInteractionEnabled3 = true
                                isInteractionEnabled4 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel9 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation{
                                navigateToComponent = true
                            }
                        }
                    )
                    
                    .transition(.move(edge: .bottom))
                    
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                Button(action: {
                    showNavigationPage = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Navigation")
                        .frame(width: 50, height: 50)
                }
                .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = false
                            isSwitch2On = false
                            isSwitch3On = false
                            isSwitch4On = false
                            isFirstAppear1 = true
                            isFirstAppear2 = true
                            isFirstAppear3 = true
                            isFirstAppear4 = true
                            isInteractionEnabled1 = true
                            isInteractionEnabled2 = true
                            isInteractionEnabled3 = true
                            isInteractionEnabled4 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel9) {
                Level9View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
        }
        .navigationBarHidden(true)
    }
}

struct Level9View: View {
    @State private var isSwitch1On = false
    @State private var isSwitch2On = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel10 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var navigateToMenu = false
    @State private var showNavigationPage = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    let switch1Position = CGPoint(x: UIScreen.main.bounds.width/4.9, y: UIScreen.main.bounds.height/2)
    let switch2Position = CGPoint(x: UIScreen.main.bounds.width/4.9, y: UIScreen.main.bounds.height/2+68)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level9 Wire Chinese")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 590, height: 295)
                        .position(x: switch1Position.x + 342, y: switch1Position.y + 17.5)
                }
                else {
                    Image("Level9 Wire")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 590, height: 295)
                        .position(x: switch1Position.x + 342, y: switch1Position.y + 17.5)
                }
                
                Image("Bulb ON")
                    .position(x: switch1Position.x+600, y: switch1Position.y-1)
                    .opacity(isSwitch1On && isSwitch2On ? 0 : 1)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitch1On && isSwitch2On)
                
                
                Image("Bulb OFF")
                    .position(x: switch1Position.x+600, y: switch1Position.y-1)
                    .opacity(isSwitch1On && isSwitch2On ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitch1On && isSwitch2On)
                
                if isFirstAppear1{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if isFirstAppear2{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = false
                                isSwitch2On = false
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel10 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation{
                                navigateToComponent = true
                            }
                        }
                    )
                    
                    .transition(.move(edge: .bottom))
                    
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                Button(action: {
                    showNavigationPage = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Navigation")
                        .frame(width: 50, height: 50)
                }
                .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = false
                            isSwitch2On = false
                            isFirstAppear1 = true
                            isFirstAppear2 = true
                            isInteractionEnabled1 = true
                            isInteractionEnabled2 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel10) {
                Level10View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
        }
        .navigationBarHidden(true)
    }
}
struct Level10View: View {
    @State private var isSwitch1On = false
    @State private var isSwitch2On = false
    @State private var isSwitch3On = false
    @State private var isSwitch4On = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel11 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isFirstAppear3 = true
    @State private var isFirstAppear4 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @State private var isInteractionEnabled3 = true
    @State private var isInteractionEnabled4 = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/4.9, y: UIScreen.main.bounds.height/3)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width/4.9, y: UIScreen.main.bounds.height/3+53)
    let switchPosition3 = CGPoint(x: UIScreen.main.bounds.width/4.9, y: UIScreen.main.bounds.height/3+128)
    let switchPosition4 = CGPoint(x: UIScreen.main.bounds.width/4.9, y: UIScreen.main.bounds.height/3+181)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level10 Wire Chinese")
                        .position(x: switchPosition.x + 308, y: switchPosition.y+102)
                }
                else {
                    Image("Level10 Wire")
                        .position(x: switchPosition.x + 308, y: switchPosition.y+102)
                }
                
                Image("Bulb OFF")
                        .position(x: switchPosition.x+565, y: switchPosition.y+55)
                
                Image("Bulb ON")
                    .position(x: switchPosition.x+565, y: switchPosition.y+55)
                    .opacity((!(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On)) ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On))
                
                if isFirstAppear1{
                    Image("Level Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)

                }
                
                if isFirstAppear2{
                    Image("Level Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switchPosition2)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }

                if isFirstAppear3{
                    Image("Level Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switchPosition3)
                        .onTapGesture {
                            isFirstAppear3 = false
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch3On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition3)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition3)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }

                if isFirstAppear4{
                    Image("Level Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switchPosition4)
                        .onTapGesture {
                            isFirstAppear4 = false
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch4On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition4)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition4)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = false
                                isSwitch2On = false
                                isSwitch3On = false
                                isSwitch4On = false
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isFirstAppear3 = true
                                isFirstAppear4 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                                isInteractionEnabled3 = true
                                isInteractionEnabled4 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel11 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation {
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = false
                            isSwitch2On = false
                            isSwitch3On = false
                            isSwitch4On = false
                            isFirstAppear1 = false
                            isFirstAppear2 = false
                            isFirstAppear3 = false
                            isFirstAppear4 = false
                            isInteractionEnabled1 = true
                            isInteractionEnabled2 = true
                            isInteractionEnabled3 = true
                            isInteractionEnabled4 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel11) {
                Level11View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}

struct Level11View: View {
    @State private var isSwitch1On = false
    @State private var isSwitch2On = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel12 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @State private var infoAppear = false
    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/4.1, y: UIScreen.main.bounds.height/2.1)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width/4.1, y: UIScreen.main.bounds.height/2.1+90)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level11 Wire Chinese")
                        .position(x: switchPosition.x + 268, y: switchPosition.y+44)
                }
                else {
                    Image("Level11 Wire")
                        .position(x: switchPosition.x + 268, y: switchPosition.y+44)
                }
                
                Image("Bulb OFF")
                        .position(x: switchPosition.x+478, y: switchPosition.y+9)
                
                Image("Bulb ON")
                    .position(x: switchPosition.x+478, y: switchPosition.y+9)
                    .opacity(isSwitch1On || isSwitch2On ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitch1On || isSwitch2On)
                
                if isFirstAppear1{
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On || isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On || isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On || isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if isFirstAppear2{
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On || isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled1 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On || isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On || isSwitch2On{
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                let InfoButtonPosition = CGPoint(x: 175, y: 64)
                
                Button(action: {
                    infoAppear = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("InfoButton")
                        .frame(width: 50, height: 50)
                }
                .position(InfoButtonPosition)
                
                if infoAppear {
                    if languageEnabled {
                        Image("Info Screen For Or Chinese")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    else {
                        Image("Info Screen For Or")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }

                    Button(action: {
                        infoAppear = false
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Cancel Button")
                            .frame(width: 50, height: 50)
                    }
                    .position(x: InfoScreenPosition.x + 275, y: InfoScreenPosition.y - 125)
                }
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = false
                                isSwitch2On = false
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel12 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation {
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = false
                            isSwitch2On = false
                            isFirstAppear1 = false
                            isFirstAppear2 = false
                            isInteractionEnabled1 = true
                            isInteractionEnabled2 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel12) {
                Level12View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}

struct Level12View: View {
    @State private var isSwitch1On = true
    @State private var isSwitch2On = true
    @State private var showFinishedPage = false
    @State private var navigateToLevel13 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/4.10, y: UIScreen.main.bounds.height/2.1)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width/4.10, y: UIScreen.main.bounds.height/2.1+90)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level12 Wire Chinese")
                        .position(x: switchPosition.x + 268, y: switchPosition.y+52)
                }
                else {
                    Image("Level12 Wire")
                        .position(x: switchPosition.x + 268, y: switchPosition.y+52)
                }
                
                Image("Bulb OFF")
                        .position(x: switchPosition.x+478, y: switchPosition.y+4)
                
                Image("Bulb ON")
                    .position(x: switchPosition.x+478, y: switchPosition.y+4)
                    .opacity(isSwitch1On || isSwitch2On ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitch1On || isSwitch2On)
                
                if isFirstAppear1{
                    Image("Level Switch On")
                        .frame(width:124, height:62)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
         .disabled(!isInteractionEnabled2)
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if isFirstAppear2{
                    Image("Level Switch On")
                        .frame(width:124, height:62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
         .disabled(!isInteractionEnabled2)
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled2)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = true
                                isSwitch2On = true
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel13 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation {
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = true
                            isSwitch2On = true
                            isInteractionEnabled1 = true
                            isInteractionEnabled2 = true
                            isFirstAppear1 = false
                            isFirstAppear2 = false
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel13) {
                Level13View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}
struct Level13View: View {
    @State private var isSwitch1On = true
    @State private var isSwitch2On = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel14 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var navigateToMenu = false
    @State private var showNavigationPage = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    let switch1Position = CGPoint(x: UIScreen.main.bounds.width/3.9, y: UIScreen.main.bounds.height/2.181)
    let switch2Position = CGPoint(x: UIScreen.main.bounds.width/3.9, y: UIScreen.main.bounds.height/2.181+88)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level13 Wire Chinese")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 500, height: 250)
                        .position(x: switch1Position.x + 291, y: switch1Position.y + 51)
                }
                else {
                    Image("Level13 Wire")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 500, height: 250)
                        .position(x: switch1Position.x + 291, y: switch1Position.y + 51)
                }
                
                Image("Bulb ON")
                    .position(x: switch1Position.x+518, y: switch1Position.y+5)
                    .opacity(!(isSwitch1On || !isSwitch2On) ? 0 : 1)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: !(isSwitch1On || !isSwitch2On))
                
                
                Image("Bulb OFF")
                    .position(x: switch1Position.x+518, y: switch1Position.y+5)
                    .opacity(!(isSwitch1On || !isSwitch2On) ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: !(isSwitch1On || !isSwitch2On))
                
                if isFirstAppear1{
                    Image("Level Switch On")
                        .resizable()
                        .frame(width:124, height:62)
                        .position(switch1Position)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || !isSwitch2On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width:124, height:62)
                        .position(switch1Position)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || !isSwitch2On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width:124, height:62)
                        .position(switch1Position)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || !isSwitch2On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if isFirstAppear2{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:124, height:62)
                        .position(switch2Position)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || !isSwitch2On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width:124, height:62)
                        .position(switch2Position)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || !isSwitch2On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width:124, height:62)
                        .position(switch2Position)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || !isSwitch2On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = true
                                isSwitch2On = false
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel14 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation{
                                navigateToComponent = true
                            }
                        }
                    )
                    
                    .transition(.move(edge: .bottom))
                    
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                Button(action: {
                    showNavigationPage = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Navigation")
                        .frame(width: 50, height: 50)
                }
                .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = true
                            isSwitch2On = false
                            isFirstAppear1 = true
                            isFirstAppear2 = true
                            isInteractionEnabled1 = true
                            isInteractionEnabled2 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel14) {
                Level14View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
        }
        .navigationBarHidden(true)
    }
}

struct Level14View: View {
    @State private var isSwitch1On = true
    @State private var isSwitch2On = false
    @State private var isSwitch3On = true
    @State private var isSwitch4On = true
    @State private var showFinishedPage = false
    @State private var navigateToLevel15 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var navigateToMenu = false
    @State private var showNavigationPage = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isFirstAppear3 = true
    @State private var isFirstAppear4 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @State private var isInteractionEnabled3 = true
    @State private var isInteractionEnabled4 = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    let switch1Position = CGPoint(x: UIScreen.main.bounds.width/4.6, y: UIScreen.main.bounds.height/2.7)
    let switch2Position = CGPoint(x: UIScreen.main.bounds.width/4.6, y: UIScreen.main.bounds.height/2.7+53)
    let switch3Position = CGPoint(x: UIScreen.main.bounds.width/4.6, y: UIScreen.main.bounds.height/2.7+130)
    let switch4Position = CGPoint(x: UIScreen.main.bounds.width/4.6, y: UIScreen.main.bounds.height/2.7+183)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level14 Wire Chinese")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 620, height: 310)
                        .position(x: switch1Position.x + 344, y: switch1Position.y + 94)
                }
                else {
                    Image("Level14 Wire")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 620, height: 310)
                        .position(x: switch1Position.x + 344, y: switch1Position.y + 94)
                }
                
                Image("Bulb OFF")
                    .position(x: switch1Position.x+574, y: switch1Position.y+43)
                    .opacity(!((isSwitch1On || isSwitch2On) || (isSwitch3On || isSwitch4On)) ? 0 : 1)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: !((isSwitch1On || isSwitch2On) || (isSwitch3On || isSwitch4On)))
                
                
                Image("Bulb ON")
                    .position(x: switch1Position.x+574, y: switch1Position.y+43)
                    .opacity(!((isSwitch1On || isSwitch2On) || (isSwitch3On || isSwitch4On)) ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: !((isSwitch1On || isSwitch2On) || (isSwitch3On || isSwitch4On)))
                
                if isFirstAppear1{
                    Image("Level Switch On")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || isSwitch2On) || (isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || isSwitch2On) || (isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || isSwitch2On) || (isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if isFirstAppear2{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || isSwitch2On) || (isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || isSwitch2On) || (isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || isSwitch2On) || (isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                
                if isFirstAppear3{
                    Image("Level Switch On")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch3Position)
                        .onTapGesture {
                            isFirstAppear3 = false
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || isSwitch2On) || (isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                }
                else if isSwitch3On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch3Position)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || isSwitch2On) || (isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch3Position)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || isSwitch2On) || (isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                }
                
                if isFirstAppear4{
                    Image("Level Switch On")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch4Position)
                        .onTapGesture {
                            isFirstAppear4 = false
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || isSwitch2On) || (isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                }
                else if isSwitch4On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch4Position)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || isSwitch2On) || (isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch4Position)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || isSwitch2On) || (isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                }
                
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = true
                                isSwitch2On = false
                                isSwitch3On = true
                                isSwitch4On = true
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isFirstAppear3 = true
                                isFirstAppear4 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                                isInteractionEnabled3 = true
                                isInteractionEnabled4 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel15 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation{
                                navigateToComponent = true
                            }
                        }
                    )
                    
                    .transition(.move(edge: .bottom))
                    
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                Button(action: {
                    showNavigationPage = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Navigation")
                        .frame(width: 50, height: 50)
                }
                .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = true
                            isSwitch2On = false
                            isSwitch3On = true
                            isSwitch4On = true
                            isFirstAppear1 = true
                            isFirstAppear2 = true
                            isFirstAppear3 = true
                            isFirstAppear4 = true
                            isInteractionEnabled1 = true
                            isInteractionEnabled2 = true
                            isInteractionEnabled3 = true
                            isInteractionEnabled4 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel15) {
                Level15View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
        }
        .navigationBarHidden(true)
    }
}

struct Level15View: View {
    @State private var isSwitch1On = true
    @State private var isSwitch2On = false
    @State private var isSwitch3On = true
    @State private var isSwitch4On = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel16 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var navigateToMenu = false
    @State private var showNavigationPage = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isFirstAppear3 = true
    @State private var isFirstAppear4 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @State private var isInteractionEnabled3 = true
    @State private var isInteractionEnabled4 = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    let switch1Position = CGPoint(x: UIScreen.main.bounds.width/5.6, y: UIScreen.main.bounds.height/2.5)
    let switch2Position = CGPoint(x: UIScreen.main.bounds.width/5.6, y: UIScreen.main.bounds.height/2.5+37)
    let switch3Position = CGPoint(x: UIScreen.main.bounds.width/5.6, y: UIScreen.main.bounds.height/2.5+111)
    let switch4Position = CGPoint(x: UIScreen.main.bounds.width/5.6, y: UIScreen.main.bounds.height/2.5+148)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level15 Wire Chinese")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 610, height: 305)
                        .position(x: switch1Position.x + 330, y: switch1Position.y + 89)
                }
                else {
                    Image("Level15 Wire")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 610, height: 305)
                        .position(x: switch1Position.x + 330, y: switch1Position.y + 89)
                }
                
                Image("Bulb OFF")
                    .position(x: switch1Position.x+633, y: switch1Position.y+30)
                    .opacity(!((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)) ? 0 : 1)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)))
                
                
                Image("Bulb ON")
                    .position(x: switch1Position.x+633, y: switch1Position.y+30)
                    .opacity(!((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)) ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)))
                
                if isFirstAppear1{
                    Image("Level Switch On")
                        .resizable()
                        .frame(width:67, height:33.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On3")
                        .frame(width:67, height:33.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off3")
                        .frame(width:67, height:33.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if isFirstAppear2{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:67, height:33.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On3")
                        .frame(width:67, height:33.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off3")
                        .frame(width:67, height:33.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                
                if isFirstAppear3{
                    Image("Level Switch On")
                        .resizable()
                        .frame(width:67, height:33.5)
                        .position(switch3Position)
                        .onTapGesture {
                            isFirstAppear3 = false
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                }
                else if isSwitch3On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On3")
                        .frame(width:67, height:33.5)
                        .position(switch3Position)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off3")
                        .frame(width:67, height:33.5)
                        .position(switch3Position)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                }
                
                if isFirstAppear4{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:67, height:33.5)
                        .position(switch4Position)
                        .onTapGesture {
                            isFirstAppear4 = false
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                }
                else if isSwitch4On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On3")
                        .frame(width:67, height:33.5)
                        .position(switch4Position)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off3")
                        .frame(width:67, height:33.5)
                        .position(switch4Position)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                }
                
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = true
                                isSwitch2On = false
                                isSwitch3On = true
                                isSwitch4On = false
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isFirstAppear3 = true
                                isFirstAppear4 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                                isInteractionEnabled3 = true
                                isInteractionEnabled4 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel16 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation{
                                navigateToComponent = true
                            }
                        }
                    )
                    
                    .transition(.move(edge: .bottom))
                    
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                Button(action: {
                    showNavigationPage = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Navigation")
                        .frame(width: 50, height: 50)
                }
                .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = true
                            isSwitch2On = false
                            isSwitch3On = true
                            isSwitch4On = false
                            isFirstAppear1 = true
                            isFirstAppear2 = true
                            isFirstAppear3 = true
                            isFirstAppear4 = true
                            isInteractionEnabled1 = true
                            isInteractionEnabled2 = true
                            isInteractionEnabled3 = true
                            isInteractionEnabled4 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel16) {
                Level16View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
        }
        .navigationBarHidden(true)
    }
}

struct Level16View: View {
    @State private var isSwitch1On = false
    @State private var isSwitch2On = false
    @State private var isSwitch3On = false
    @State private var isSwitch4On = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel17 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var navigateToMenu = false
    @State private var showNavigationPage = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isFirstAppear3 = true
    @State private var isFirstAppear4 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @State private var isInteractionEnabled3 = true
    @State private var isInteractionEnabled4 = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    let switch1Position = CGPoint(x: UIScreen.main.bounds.width/4.7, y: UIScreen.main.bounds.height/2.8)
    let switch2Position = CGPoint(x: UIScreen.main.bounds.width/4.7, y: UIScreen.main.bounds.height/2.8+54)
    let switch3Position = CGPoint(x: UIScreen.main.bounds.width/4.7, y: UIScreen.main.bounds.height/2.8+133)
    let switch4Position = CGPoint(x: UIScreen.main.bounds.width/4.7, y: UIScreen.main.bounds.height/2.8+187)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level16 Wire Chinese")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 610, height: 305)
                        .position(x: switch1Position.x + 347, y: switch1Position.y + 107.5)
                }
                else {
                    Image("Level16 Wire")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 610, height: 305)
                        .position(x: switch1Position.x + 347, y: switch1Position.y + 107.5)
                }
                
                Image("Bulb OFF")
                    .position(x: switch1Position.x+573.6, y: switch1Position.y+59)
                    .opacity((isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) ? 0 : 1)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: (isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On))
                
                
                Image("Bulb ON")
                    .position(x: switch1Position.x+573.6, y: switch1Position.y+59)
                    .opacity((isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: (isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On))
                
                if isFirstAppear1{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if isFirstAppear2{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                
                if isFirstAppear3{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch3Position)
                        .onTapGesture {
                            isFirstAppear3 = false
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                }
                else if isSwitch3On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch3Position)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch3Position)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                }
                
                if isFirstAppear4{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch4Position)
                        .onTapGesture {
                            isFirstAppear4 = false
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                }
                else if isSwitch4On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch4Position)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch4Position)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                }
                
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = false
                                isSwitch2On = false
                                isSwitch3On = false
                                isSwitch4On = false
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isFirstAppear3 = true
                                isFirstAppear4 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                                isInteractionEnabled3 = true
                                isInteractionEnabled4 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel17 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation{
                                navigateToComponent = true
                            }
                        }
                    )
                    
                    .transition(.move(edge: .bottom))
                    
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                Button(action: {
                    showNavigationPage = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Navigation")
                        .frame(width: 50, height: 50)
                }
                .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = false
                            isSwitch2On = false
                            isSwitch3On = false
                            isSwitch4On = false
                            isFirstAppear1 = true
                            isFirstAppear2 = true
                            isFirstAppear3 = true
                            isFirstAppear4 = true
                            isInteractionEnabled1 = true
                            isInteractionEnabled2 = true
                            isInteractionEnabled3 = true
                            isInteractionEnabled4 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel17) {
                Level17View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
        }
        .navigationBarHidden(true)
    }
}

struct Level17View: View {
    @State private var isSwitch1On = true
    @State private var isSwitch2On = true
    @State private var isSwitch3On = false
    @State private var isSwitch4On = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel18 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var navigateToMenu = false
    @State private var showNavigationPage = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isFirstAppear3 = true
    @State private var isFirstAppear4 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @State private var isInteractionEnabled3 = true
    @State private var isInteractionEnabled4 = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    let switch1Position = CGPoint(x: UIScreen.main.bounds.width/4.7, y: UIScreen.main.bounds.height/2.8)
    let switch2Position = CGPoint(x: UIScreen.main.bounds.width/4.7, y: UIScreen.main.bounds.height/2.8+54)
    let switch3Position = CGPoint(x: UIScreen.main.bounds.width/4.7, y: UIScreen.main.bounds.height/2.8+133)
    let switch4Position = CGPoint(x: UIScreen.main.bounds.width/4.7, y: UIScreen.main.bounds.height/2.8+187)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level17 Wire Chinese")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 610, height: 305)
                        .position(x: switch1Position.x + 316.5, y: switch1Position.y + 106)
                }
                else {
                    Image("Level17 Wire")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 610, height: 305)
                        .position(x: switch1Position.x + 316.5, y: switch1Position.y + 106)
                }
                
                Image("Bulb OFF")
                    .position(x: switch1Position.x+582.7, y: switch1Position.y+54)
                    .opacity(!(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) ? 0 : 1)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On))
                
                
                Image("Bulb ON")
                    .position(x: switch1Position.x+582.7, y: switch1Position.y+54)
                    .opacity(!(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On))
                
                if isFirstAppear1{
                    Image("Level Switch On")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if isFirstAppear2{
                    Image("Level Switch On")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                
                if isFirstAppear3{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch3Position)
                        .onTapGesture {
                            isFirstAppear3 = false
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                }
                else if isSwitch3On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch3Position)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch3Position)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                }
                
                if isFirstAppear4{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch4Position)
                        .onTapGesture {
                            isFirstAppear4 = false
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                }
                else if isSwitch4On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch4Position)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch4Position)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                }
                
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = true
                                isSwitch2On = true
                                isSwitch3On = false
                                isSwitch4On = false
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isFirstAppear3 = true
                                isFirstAppear4 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                                isInteractionEnabled3 = true
                                isInteractionEnabled4 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel18 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation{
                                navigateToComponent = true
                            }
                        }
                    )
                    
                    .transition(.move(edge: .bottom))
                    
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                Button(action: {
                    showNavigationPage = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Navigation")
                        .frame(width: 50, height: 50)
                }
                .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = true
                            isSwitch2On = true
                            isSwitch3On = false
                            isSwitch4On = false
                            isFirstAppear1 = true
                            isFirstAppear2 = true
                            isFirstAppear3 = true
                            isFirstAppear4 = true
                            isInteractionEnabled1 = true
                            isInteractionEnabled2 = true
                            isInteractionEnabled3 = true
                            isInteractionEnabled4 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel18) {
                Level18View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
        }
        .navigationBarHidden(true)
    }
}

struct Level18View: View {
    @State private var isSwitch1On = true
    @State private var isSwitch2On = true
    @State private var showFinishedPage = false
    @State private var navigateToLevel19 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @State private var infoAppear = false
    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/4.15, y: UIScreen.main.bounds.height/2.1)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width/4.15, y: UIScreen.main.bounds.height/2.1+93)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level18 Wire Chinese")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 580, height: 290)
                        .position(x: switchPosition.x + 275, y: switchPosition.y+41.5)
                }
                else {
                    Image("Level18 Wire")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 580, height: 290)
                        .position(x: switchPosition.x + 275, y: switchPosition.y+41.5)
                }
                
                Image("Bulb OFF")
                    .position(x: switchPosition.x+502.7, y: switchPosition.y+11)
                
                Image("Bulb ON")
                    .position(x: switchPosition.x+502.7, y: switchPosition.y+11)
                    .opacity(!(isSwitch1On || isSwitch2On) ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: !(isSwitch1On || isSwitch2On))
                
                if isFirstAppear1{
                    Image("Level Switch On")
                        .frame(width:124, height:62)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if isFirstAppear2{
                    Image("Level Switch On")
                        .frame(width:124, height:62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled1 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                let InfoButtonPosition = CGPoint(x: 175, y: 64)
                
                Button(action: {
                    infoAppear = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("InfoButton")
                        .frame(width: 50, height: 50)
                }
                .position(InfoButtonPosition)
                
                if infoAppear {
                    if languageEnabled {
                        Image("Info Screen For Nor Chinese")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    else {
                        Image("Info Screen For Nor")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    
                    Button(action: {
                        infoAppear = false
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Cancel Button")
                            .frame(width: 50, height: 50)
                    }
                    .position(x: InfoScreenPosition.x + 275, y: InfoScreenPosition.y - 125)
                }
                
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = true
                                isSwitch2On = true
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel19 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation {
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = true
                            isSwitch2On = true
                            isFirstAppear1 = false
                            isFirstAppear2 = false
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel19) {
                Level19View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}

struct Level19View: View {
    @State private var isSwitch1On = true
    @State private var isSwitch2On = true
    @State private var isSwitch3On = false
    @State private var isSwitch4On = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel20 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var navigateToMenu = false
    @State private var showNavigationPage = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isFirstAppear3 = true
    @State private var isFirstAppear4 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @State private var isInteractionEnabled3 = true
    @State private var isInteractionEnabled4 = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    let switch1Position = CGPoint(x: UIScreen.main.bounds.width/5.2, y: UIScreen.main.bounds.height/2.8)
    let switch2Position = CGPoint(x: UIScreen.main.bounds.width/5.2, y: UIScreen.main.bounds.height/2.8+53)
    let switch3Position = CGPoint(x: UIScreen.main.bounds.width/5.2, y: UIScreen.main.bounds.height/2.8+128)
    let switch4Position = CGPoint(x: UIScreen.main.bounds.width/5.2, y: UIScreen.main.bounds.height/2.8+181)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level19 Wire Chinese")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 589, height: 294.5)
                        .position(x: switch1Position.x + 343.5, y: switch1Position.y + 103)
                }
                else {
                    Image("Level19 Wire")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 589, height: 294.5)
                        .position(x: switch1Position.x + 343.5, y: switch1Position.y + 103)
                }
                
                Image("Bulb OFF")
                    .position(x: switch1Position.x+563, y: switch1Position.y+55)
                    .opacity(!(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) ? 0 : 1)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On))
                
                
                Image("Bulb ON")
                    .position(x: switch1Position.x+563, y: switch1Position.y+55)
                    .opacity(!(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On))
                
                if isFirstAppear1{
                    Image("Level Switch On")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch1Position)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if isFirstAppear2{
                    Image("Level Switch On")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch2Position)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                
                if isFirstAppear3{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch3Position)
                        .onTapGesture {
                            isFirstAppear3 = false
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                }
                else if isSwitch3On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch3Position)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch3Position)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                }
                
                if isFirstAppear4{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:97, height:48.5)
                        .position(switch4Position)
                        .onTapGesture {
                            isFirstAppear4 = false
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                }
                else if isSwitch4On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switch4Position)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switch4Position)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) && (isSwitch3On && isSwitch4On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                }
                
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = true
                                isSwitch2On = true
                                isSwitch3On = false
                                isSwitch4On = false
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isFirstAppear3 = true
                                isFirstAppear4 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                                isInteractionEnabled3 = true
                                isInteractionEnabled4 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel20 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation{
                                navigateToComponent = true
                            }
                        }
                    )
                    
                    .transition(.move(edge: .bottom))
                    
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                Button(action: {
                    showNavigationPage = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Navigation")
                        .frame(width: 50, height: 50)
                }
                .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = true
                            isSwitch2On = true
                            isSwitch3On = false
                            isSwitch4On = false
                            isFirstAppear1 = true
                            isFirstAppear2 = true
                            isFirstAppear3 = true
                            isFirstAppear4 = true
                            isInteractionEnabled1 = true
                            isInteractionEnabled2 = true
                            isInteractionEnabled3 = true
                            isInteractionEnabled4 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel20) {
                Level20View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
        }
        .navigationBarHidden(true)
    }
}

struct Level20View: View {
    @State private var isSwitch1On = false
    @State private var isSwitch2On = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel21 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @State private var infoAppear = false
    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/4, y: UIScreen.main.bounds.height/2.1)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width/4, y: UIScreen.main.bounds.height/2.1+93)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level20 Wire Chinese")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 580, height: 290)
                        .position(x: switchPosition.x + 293, y: switchPosition.y+35)
                }
                else {
                    Image("Level20 Wire")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 580, height: 290)
                        .position(x: switchPosition.x + 293, y: switchPosition.y+35)
                }
                
                Image("Bulb ON")
                    .position(x: switchPosition.x+519, y: switchPosition.y+6)
                    .opacity(!(isSwitch1On && isSwitch2On) ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: !(isSwitch1On && isSwitch2On))
                
                Image("Bulb OFF")
                    .position(x: switchPosition.x+519, y: switchPosition.y+6)
                    .opacity(!(isSwitch1On && isSwitch2On) ? 0 : 1)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitch1On && isSwitch2On)
                
                if isFirstAppear1{
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if isFirstAppear2{
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled1 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On && isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                let InfoButtonPosition = CGPoint(x: 175, y: 64)
                
                Button(action: {
                    infoAppear = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("InfoButton")
                        .frame(width: 50, height: 50)
                }
                .position(InfoButtonPosition)
                
                if infoAppear {
                    if languageEnabled {
                        Image("Info Screen For Nand Chinese")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    else {
                        Image("Info Screen For Nand")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }

                    Button(action: {
                        infoAppear = false
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Cancel Button")
                            .frame(width: 50, height: 50)
                    }
                    .position(x: InfoScreenPosition.x + 275, y: InfoScreenPosition.y - 125)
                }
                
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = false
                                isSwitch2On = false
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel21 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation {
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = false
                            isSwitch2On = false
                            isFirstAppear1 = false
                            isFirstAppear2 = false
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel21) {
                Level21View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}


struct Level21View: View {
    @State private var isSwitch1On = false
    @State private var isSwitch2On = false
    @State private var isSwitch3On = false
    @State private var isSwitch4On = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel22 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isFirstAppear3 = true
    @State private var isFirstAppear4 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @State private var isInteractionEnabled3 = true
    @State private var isInteractionEnabled4 = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/4.9, y: UIScreen.main.bounds.height/3.1)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width/4.9, y: UIScreen.main.bounds.height/3.1+53)
    let switchPosition3 = CGPoint(x: UIScreen.main.bounds.width/4.9, y: UIScreen.main.bounds.height/3.1+128)
    let switchPosition4 = CGPoint(x: UIScreen.main.bounds.width/4.9, y: UIScreen.main.bounds.height/3.1+181)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level21 Wire Chinese")
                        .position(x: switchPosition.x + 328, y: switchPosition.y+102)
                }
                else {
                    Image("Level21 Wire")
                        .position(x: switchPosition.x + 328, y: switchPosition.y+102)
                }
                
                Image("Bulb OFF")
                        .position(x: switchPosition.x+547, y: switchPosition.y+57)
                
                Image("Bulb ON")
                    .position(x: switchPosition.x+547, y: switchPosition.y+57)
                    .opacity((!(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On)) ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On))
                
                if isFirstAppear1{
                    Image("Level Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)

                }
                
                if isFirstAppear2{
                    Image("Level Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switchPosition2)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }

                if isFirstAppear3{
                    Image("Level Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switchPosition3)
                        .onTapGesture {
                            isFirstAppear3 = false
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch3On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition3)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width: 124, height: 62)
                        .position(switchPosition3)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }

                if isFirstAppear4{
                    Image("Level Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switchPosition4)
                        .onTapGesture {
                            isFirstAppear4 = false
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch4On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition4)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width: 124, height: 62)
                        .position(switchPosition4)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On && isSwitch2On) && (isSwitch3On && isSwitch4On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = false
                                isSwitch2On = false
                                isSwitch3On = false
                                isSwitch4On = false
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isFirstAppear3 = true
                                isFirstAppear4 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                                isInteractionEnabled3 = true
                                isInteractionEnabled4 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel22 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation {
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = false
                            isSwitch2On = false
                            isSwitch3On = false
                            isSwitch4On = false
                            isFirstAppear1 = false
                            isFirstAppear2 = false
                            isFirstAppear3 = false
                            isFirstAppear4 = false
                            isInteractionEnabled1 = true
                            isInteractionEnabled2 = true
                            isInteractionEnabled3 = true
                            isInteractionEnabled4 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel22) {
                Level22View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}

struct Level22View: View {
    @State private var isSwitch1On = true
    @State private var isSwitch2On = false
    @State private var isSwitch3On = true
    @State private var isSwitch4On = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel23 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isFirstAppear3 = true
    @State private var isFirstAppear4 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @State private var isInteractionEnabled3 = true
    @State private var isInteractionEnabled4 = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/5.2, y: UIScreen.main.bounds.height/2.8)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width/5.2, y: UIScreen.main.bounds.height/2.8+53)
    let switchPosition3 = CGPoint(x: UIScreen.main.bounds.width/5.2, y: UIScreen.main.bounds.height/2.8+128)
    let switchPosition4 = CGPoint(x: UIScreen.main.bounds.width/5.2, y: UIScreen.main.bounds.height/2.8+181)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level22 Wire Chinese")
                        .position(x: switchPosition.x + 352, y: switchPosition.y+103)
                }
                else {
                    Image("Level22 Wire")
                        .position(x: switchPosition.x + 352, y: switchPosition.y+103)
                }
                
                Image("Bulb OFF")
                        .position(x: switchPosition.x+586, y: switchPosition.y+65)
                
                Image("Bulb ON")
                    .position(x: switchPosition.x+586, y: switchPosition.y+65)
                    .opacity(!((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)) ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)))
                
                if isFirstAppear1{
                    Image("Level Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)

                }
                
                if isFirstAppear2{
                    Image("Level Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switchPosition2)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }

                if isFirstAppear3{
                    Image("Level Switch On2")
                        .frame(width:97, height:48.5)
                        .position(switchPosition3)
                        .onTapGesture {
                            isFirstAppear3 = false
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch3On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition3)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition3)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }

                if isFirstAppear4{
                    Image("Level Switch Off2")
                        .frame(width:97, height:48.5)
                        .position(switchPosition4)
                        .onTapGesture {
                            isFirstAppear4 = false
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch4On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition4)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition4)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if !((isSwitch1On || !isSwitch2On) || !(!isSwitch3On || isSwitch4On)){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = true
                                isSwitch2On = false
                                isSwitch3On = true
                                isSwitch4On = false
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isFirstAppear3 = true
                                isFirstAppear4 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                                isInteractionEnabled3 = true
                                isInteractionEnabled4 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel23 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation {
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = false
                            isSwitch2On = false
                            isSwitch3On = false
                            isSwitch4On = false
                            isFirstAppear1 = false
                            isFirstAppear2 = false
                            isFirstAppear3 = false
                            isFirstAppear4 = false
                            isInteractionEnabled1 = true
                            isInteractionEnabled2 = true
                            isInteractionEnabled3 = true
                            isInteractionEnabled4 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel23) {
                Level23View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}

struct Level23View: View {
    @State private var isSwitch1On = true
    @State private var isSwitch2On = true
    @State private var showFinishedPage = false
    @State private var navigateToLevel24 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/4.60, y: UIScreen.main.bounds.height/1.95)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width/4.60, y: UIScreen.main.bounds.height/1.95+67)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level23 Wire Chinese")
                        .position(x: switchPosition.x + 331, y: switchPosition.y+17)
                }
                else {
                    Image("Level23 Wire")
                        .position(x: switchPosition.x + 331, y: switchPosition.y+17)
                }
                
                Image("Bulb ON")
                        .position(x: switchPosition.x+579, y: switchPosition.y+8)
                        .opacity(!(isSwitch1On || isSwitch2On) ? 0 : 1)
                        .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: !(isSwitch1On || isSwitch2On))
                Image("Bulb OFF")
                    .position(x: switchPosition.x+579, y: switchPosition.y+8)
                    .opacity(!(isSwitch1On || isSwitch2On) ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: !(isSwitch1On || isSwitch2On))
                
                if isFirstAppear1{
                    Image("Level Switch On2")
                        .frame(width:124, height:62)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)

                }
                
                if isFirstAppear2{
                    Image("Level Switch On2")
                        .frame(width:124, height:62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled1 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On){
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if !(isSwitch1On || isSwitch2On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = true
                                isSwitch2On = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel24 = true
                                }
                        },
                        onBackToComponent: {
                            withAnimation{
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = true
                            isSwitch2On = true
                            isFirstAppear1 = false
                            isFirstAppear2 = false
                            isInteractionEnabled1 = true
                            isInteractionEnabled2 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel24) {
                Level24View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}

struct Level24View: View {
    @State private var isSwitch1On = false
    @State private var isSwitch2On = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel25 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/4.60, y: UIScreen.main.bounds.height/1.45)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width/4.60, y: UIScreen.main.bounds.height/1.45+53)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level24 Wire Chinese")
                        .position(x: switchPosition.x + 331, y: switchPosition.y-27)
                }
                else {
                    Image("Level24 Wire")
                        .position(x: switchPosition.x + 331, y: switchPosition.y-27)
                }
                
                Image("Bulb OFF")
                    .position(x: switchPosition.x+550, y: switchPosition.y-74)
                Image("Bulb ON")
                        .position(x: switchPosition.x+550, y: switchPosition.y-74)
                        .opacity(isSwitch1On != isSwitch2On ? 1 : 0)
                        .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitch1On != isSwitch2On)
                
                if isFirstAppear1{
                    Image("Level Switch Off2")
                        .frame(width:124, height:62)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On{
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)

                }
                
                if isFirstAppear2{
                    Image("Level Switch Off2")
                        .frame(width:124, height:62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width: 97, height: 48.5)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = false
                                isSwitch2On = false
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel25 = true
                                }
                        },
                        onBackToComponent: {
                            withAnimation{
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = false
                            isSwitch2On = false
                            isFirstAppear1 = false
                            isFirstAppear2 = false
                            isInteractionEnabled1 = true
                            isInteractionEnabled2 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel25) {
                Level25View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}

struct Level25View: View {
    @State private var isSwitch1On = false
    @State private var isSwitch2On = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel26 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @State private var infoAppear = false
    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/4, y: UIScreen.main.bounds.height/2.3)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width/4, y: UIScreen.main.bounds.height/2.3+90)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level25 Wire Chinese")
                        .position(x: switchPosition.x + 258, y: switchPosition.y+44)
                } else {
                    Image("Level25 Wire")
                        .position(x: switchPosition.x + 258, y: switchPosition.y+44)
                }
                
                Image("Bulb OFF")
                        .position(x: switchPosition.x+480, y: switchPosition.y+9)
                
                Image("Bulb ON")
                    .position(x: switchPosition.x+480, y: switchPosition.y+9)
                    .opacity(isSwitch1On != isSwitch2On ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitch1On != isSwitch2On)
                
                if isFirstAppear1{
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if isFirstAppear2{
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled1 = false
                                    }
                                }
                            }
                        }
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                let InfoButtonPosition = CGPoint(x: 175, y: 64)
                
                Button(action: {
                    infoAppear = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("InfoButton")
                        .frame(width: 50, height: 50)
                }
                .position(InfoButtonPosition)
                
                if infoAppear {
                    if languageEnabled {
                        Image("Info Screen For Xor Chinese")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    else {
                        Image("Info Screen For Xor")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    
                    Button(action: {
                        infoAppear = false
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Cancel Button")
                            .frame(width: 50, height: 50)
                    }
                    .position(x: InfoScreenPosition.x + 275, y: InfoScreenPosition.y - 125)
                }
                
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = false
                                isSwitch2On = false
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel26 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation {
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = false
                            isSwitch2On = false
                            isFirstAppear1 = false
                            isFirstAppear2 = false
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel26) {
                Level26View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}

struct Level26View: View {
    @State private var isSwitch1On = true
    @State private var isSwitch2On = true
    @State private var showFinishedPage = false
    @State private var navigateToLevel27 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    let wirePosition = CGPoint(x: UIScreen.main.bounds.width/1.76, y: UIScreen.main.bounds.height/1.6)
    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/1.76-278, y: UIScreen.main.bounds.height/1.6-58)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width/1.76-278, y: UIScreen.main.bounds.height/1.6+41)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level26 Wire Chinese")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 560, height: 280)
                        .position(wirePosition)
                } else {
                    Image("Level26 Wire")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 560, height: 280)
                        .position(wirePosition)
                }

                Image("Bulb OFF")
                    .position(x: wirePosition.x+226.5, y: wirePosition.y-43)
                    .opacity(isSwitch1On != isSwitch2On ? 0 : 1)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitch1On != isSwitch2On)
                
                Image("Bulb ON")
                    .position(x: wirePosition.x+226.5, y: wirePosition.y-43)
                    .opacity(isSwitch1On != isSwitch2On ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitch1On != isSwitch2On)
                
                if isFirstAppear1{
                    Image("Level Switch On")
                        .frame(width:124, height:62)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if isFirstAppear2{
                    Image("Level Switch On")
                        .frame(width:124, height:62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled1 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled2)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = true
                                isSwitch2On = true
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel27 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation {
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = true
                            isSwitch2On = true
                            isFirstAppear1 = false
                            isFirstAppear2 = false
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel27) {
                Level27View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}

struct Level27View: View {
    @State private var isSwitch1On = true
    @State private var isSwitch2On = true
    @State private var showFinishedPage = false
    @State private var navigateToLevel28 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @State private var infoAppear = false
    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    let wirePosition = CGPoint(x: UIScreen.main.bounds.width/1.73, y: UIScreen.main.bounds.height/1.64)
    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/1.73-278, y: UIScreen.main.bounds.height/1.64-38)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width/1.73-278, y: UIScreen.main.bounds.height/1.64+50)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level27 Wire Chinese")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 560, height: 280)
                        .position(wirePosition)
                } else {
                    Image("Level27 Wire")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 560, height: 280)
                        .position(wirePosition)
                }
                
                Image("Bulb ON")
                    .position(x: wirePosition.x+214.5, y: wirePosition.y-34)
                    .opacity(isSwitch1On != isSwitch2On ? 0 : 1)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitch1On != isSwitch2On)
                
                Image("Bulb OFF")
                    .position(x: wirePosition.x+214.5, y: wirePosition.y-34)
                    .opacity(isSwitch1On != isSwitch2On ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitch1On != isSwitch2On)
                
                if isFirstAppear1{
                    Image("Level Switch On")
                        .frame(width:124, height:62)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if isFirstAppear2{
                    Image("Level Switch On")
                        .frame(width:124, height:62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled1 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled2)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                
                let InfoButtonPosition = CGPoint(x: 175, y: 64)
                
                Button(action: {
                    infoAppear = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("InfoButton")
                        .frame(width: 50, height: 50)
                }
                .position(InfoButtonPosition)
                
                if infoAppear {
                    if languageEnabled {
                        Image("Info Screen For Xnor Chinese")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    else {
                        Image("Info Screen For Xnor")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    
                    Button(action: {
                        infoAppear = false
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Cancel Button")
                            .frame(width: 50, height: 50)
                    }
                    .position(x: InfoScreenPosition.x + 275, y: InfoScreenPosition.y - 125)
                }
                
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = true
                                isSwitch2On = true
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel28 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation {
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = true
                            isSwitch2On = true
                            isFirstAppear1 = false
                            isFirstAppear2 = false
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel28) {
                Level28View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}

struct Level28View: View {
    @State private var isSwitch1On = false
    @State private var isSwitch2On = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel29 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    let wirePosition = CGPoint(x: UIScreen.main.bounds.width/1.75, y: UIScreen.main.bounds.height/1.64)
    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/1.75-301, y: UIScreen.main.bounds.height/1.64-60)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width/1.75-301, y: UIScreen.main.bounds.height/1.64+38)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level28 Wire Chinese")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 540, height: 270)
                        .position(wirePosition)
                } else {
                    Image("Level28 Wire")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 540, height: 270)
                        .position(wirePosition)
                }
                
                Image("Bulb ON")
                    .position(x: wirePosition.x+235.5, y: wirePosition.y-45)
                    .opacity(isSwitch1On != isSwitch2On ? 0 : 1)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitch1On != isSwitch2On)
                
                Image("Bulb OFF")
                    .position(x: wirePosition.x+235.5, y: wirePosition.y-45)
                    .opacity(isSwitch1On != isSwitch2On ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: isSwitch1On != isSwitch2On)
                
                if isFirstAppear1{
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if isFirstAppear2{
                    Image("Level Switch Off")
                        .frame(width:124, height:62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled1 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled2)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if isSwitch1On != isSwitch2On {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = false
                                isSwitch2On = false
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel29 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation {
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = false
                            isSwitch2On = false
                            isFirstAppear1 = false
                            isFirstAppear2 = false
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel29) {
                Level29View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}

struct Level29View: View {
    @State private var isSwitch1On = false
    @State private var isSwitch2On = false
    @State private var isSwitch3On = false
    @State private var isSwitch4On = false
    @State private var isSwitch5On = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel30 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isFirstAppear3 = true
    @State private var isFirstAppear4 = true
    @State private var isFirstAppear5 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @State private var isInteractionEnabled3 = true
    @State private var isInteractionEnabled4 = true
    @State private var isInteractionEnabled5 = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    let wirePosition = CGPoint(x: UIScreen.main.bounds.width/1.93, y: UIScreen.main.bounds.height/1.64)
    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/1.9-274, y: UIScreen.main.bounds.height/1.64-130)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width/1.9-274, y: UIScreen.main.bounds.height/1.64-93)
    let switchPosition3 = CGPoint(x: UIScreen.main.bounds.width/1.9-274, y: UIScreen.main.bounds.height/1.64-27)
    let switchPosition4 = CGPoint(x: UIScreen.main.bounds.width/1.9-274, y: UIScreen.main.bounds.height/1.64+10)
    let switchPosition5 = CGPoint(x: UIScreen.main.bounds.width/1.9-274, y: UIScreen.main.bounds.height/1.64+88)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level29 Wire Chinese")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 650, height: 325)
                        .position(wirePosition)
                } else {
                    Image("Level29 Wire")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 650, height: 325)
                        .position(wirePosition)
                }
                
                Image("Bulb OFF")
                    .position(x: wirePosition.x+245.5, y: wirePosition.y-45)
                    .opacity(!((!(isSwitch1On || isSwitch2On) != (isSwitch3On && isSwitch4On)) != !((isSwitch3On && isSwitch4On) && !isSwitch5On)) ? 0 : 1)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: (!(isSwitch1On || isSwitch2On) != (isSwitch3On && isSwitch4On)) != !((isSwitch3On && isSwitch4On) && !isSwitch5On))
                
                Image("Bulb ON")
                    .position(x: wirePosition.x+245.5, y: wirePosition.y-45)
                    .opacity(!((!(isSwitch1On || isSwitch2On) != (isSwitch3On && isSwitch4On)) != !((isSwitch3On && isSwitch4On) && !isSwitch5On)) ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: !((!(isSwitch1On || isSwitch2On) != (isSwitch3On && isSwitch4On)) != !((isSwitch3On && isSwitch4On) && !isSwitch5On)))
                
                if isFirstAppear1{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:67, height:33.5)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if (!(isSwitch1On || isSwitch2On) != (isSwitch3On && isSwitch4On)) != !((isSwitch3On && isSwitch4On) && !isSwitch5On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width:67, height:33.5)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if (!(isSwitch1On || isSwitch2On) != (isSwitch3On && isSwitch4On)) != !((isSwitch3On && isSwitch4On) && !isSwitch5On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width:67, height:33.5)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if (!(isSwitch1On || isSwitch2On) != (isSwitch3On && isSwitch4On)) != !((isSwitch3On && isSwitch4On) && !isSwitch5On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if isFirstAppear2{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:67, height:33.5)
                        .position(switchPosition2)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if (!(isSwitch1On || isSwitch2On) != (isSwitch3On && isSwitch4On)) != !((isSwitch3On && isSwitch4On) && !isSwitch5On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width:67, height:33.5)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if (!(isSwitch1On || isSwitch2On) != (isSwitch3On && isSwitch4On)) != !((isSwitch3On && isSwitch4On) && !isSwitch5On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled2)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width:67, height:33.5)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if (!(isSwitch1On || isSwitch2On) != (isSwitch3On && isSwitch4On)) != !((isSwitch3On && isSwitch4On) && !isSwitch5On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                
                if isFirstAppear3{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:67, height:33.5)
                        .position(switchPosition3)
                        .onTapGesture {
                            isFirstAppear3 = false
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if (!(isSwitch1On || isSwitch2On) != (isSwitch3On && isSwitch4On)) != !((isSwitch3On && isSwitch4On) && !isSwitch5On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                }
                else if isSwitch3On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width:67, height:33.5)
                        .position(switchPosition3)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if (!(isSwitch1On || isSwitch2On) != (isSwitch3On && isSwitch4On)) != !((isSwitch3On && isSwitch4On) && !isSwitch5On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled3)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width:67, height:33.5)
                        .position(switchPosition3)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if (!(isSwitch1On || isSwitch2On) != (isSwitch3On && isSwitch4On)) != !((isSwitch3On && isSwitch4On) && !isSwitch5On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                }
                
                if isFirstAppear4{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:67, height:33.5)
                        .position(switchPosition4)
                        .onTapGesture {
                            isFirstAppear4 = false
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if (!(isSwitch1On || isSwitch2On) != (isSwitch3On && isSwitch4On)) != !((isSwitch3On && isSwitch4On) && !isSwitch5On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                }
                else if isSwitch4On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width:67, height:33.5)
                        .position(switchPosition4)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if (!(isSwitch1On || isSwitch2On) != (isSwitch3On && isSwitch4On)) != !((isSwitch3On && isSwitch4On) && !isSwitch5On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled4)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width:67, height:33.5)
                        .position(switchPosition4)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if (!(isSwitch1On || isSwitch2On) != (isSwitch3On && isSwitch4On)) != !((isSwitch3On && isSwitch4On) && !isSwitch5On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                }
                
                if isFirstAppear5{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:67, height:33.5)
                        .position(switchPosition5)
                        .onTapGesture {
                            isFirstAppear5 = false
                            isSwitch5On.toggle()
                            generateHapticFeedbackHeavy()
                            if (!(isSwitch1On || isSwitch2On) != (isSwitch3On && isSwitch4On)) != !((isSwitch3On && isSwitch4On) && !isSwitch5On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled5)
                }
                else if isSwitch5On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width:67, height:33.5)
                        .position(switchPosition5)
                        .onTapGesture {
                            isSwitch5On.toggle()
                            generateHapticFeedbackHeavy()
                            if (!(isSwitch1On || isSwitch2On) != (isSwitch3On && isSwitch4On)) != !((isSwitch3On && isSwitch4On) && !isSwitch5On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled5)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width:67, height:33.5)
                        .position(switchPosition5)
                        .onTapGesture {
                            isSwitch5On.toggle()
                            generateHapticFeedbackHeavy()
                            if (!(isSwitch1On || isSwitch2On) != (isSwitch3On && isSwitch4On)) != !((isSwitch3On && isSwitch4On) && !isSwitch5On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled5)
                }
                
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = false
                                isSwitch2On = false
                                isSwitch3On = false
                                isSwitch4On = false
                                isSwitch5On = false
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isFirstAppear3 = true
                                isFirstAppear4 = true
                                isFirstAppear5 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                                isInteractionEnabled3 = true
                                isInteractionEnabled4 = true
                                isInteractionEnabled5 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel30 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation {
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = false
                            isSwitch2On = false
                            isSwitch3On = false
                            isSwitch4On = false
                            isSwitch5On = false
                            isFirstAppear1 = true
                            isFirstAppear2 = true
                            isFirstAppear3 = true
                            isFirstAppear4 = true
                            isFirstAppear5 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel30) {
                Level30View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}

struct Level30View: View {
    @State private var isSwitch1On = false
    @State private var isSwitch2On = false
    @State private var isSwitch3On = false
    @State private var isSwitch4On = false
    @State private var isSwitch5On = false
    @State private var isSwitch6On = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel31 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var isFirstAppear3 = true
    @State private var isFirstAppear4 = true
    @State private var isFirstAppear5 = true
    @State private var isFirstAppear6 = true
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @State private var isInteractionEnabled3 = true
    @State private var isInteractionEnabled4 = true
    @State private var isInteractionEnabled5 = true
    @State private var isInteractionEnabled6 = true
    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    let wirePosition = CGPoint(x: UIScreen.main.bounds.width/1.9, y: UIScreen.main.bounds.height/1.64)
    let switchPosition = CGPoint(x: UIScreen.main.bounds.width/1.9-303, y: UIScreen.main.bounds.height/1.64-129)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width/1.9-303, y: UIScreen.main.bounds.height/1.64-92)
    let switchPosition3 = CGPoint(x: UIScreen.main.bounds.width/1.9-303, y: UIScreen.main.bounds.height/1.64-27)
    let switchPosition4 = CGPoint(x: UIScreen.main.bounds.width/1.9-303, y: UIScreen.main.bounds.height/1.64+10)
    let switchPosition5 = CGPoint(x: UIScreen.main.bounds.width/1.9-303, y: UIScreen.main.bounds.height/1.64+68)
    let switchPosition6 = CGPoint(x: UIScreen.main.bounds.width/1.9-303, y: UIScreen.main.bounds.height/1.64+105)
    
    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width/1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level30 Wire Chinese")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 650, height: 325)
                        .position(wirePosition)
                } else {
                    Image("Level30 Wire")
                        .resizable()
                        .aspectRatio(contentMode: /*@START_MENU_TOKEN@*/.fit/*@END_MENU_TOKEN@*/)
                        .frame(width: 650, height: 325)
                        .position(wirePosition)
                }
                
                Image("Bulb OFF")
                    .position(x: wirePosition.x+272, y: wirePosition.y-47)
                    .opacity((isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On) ? 0 : 1)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: (isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On))
                
                Image("Bulb ON")
                    .position(x: wirePosition.x+272, y: wirePosition.y-47)
                    .opacity((isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On) ? 1 : 0)
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: (isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On))
                
                if isFirstAppear1{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:67, height:33.5)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                isInteractionEnabled6 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                        isInteractionEnabled6 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width:67, height:33.5)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                isInteractionEnabled6 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                        isInteractionEnabled6 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width:67, height:33.5)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                isInteractionEnabled6 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                        isInteractionEnabled6 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if isFirstAppear2{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:67, height:33.5)
                        .position(switchPosition2)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                isInteractionEnabled6 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                        isInteractionEnabled6 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width:67, height:33.5)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                isInteractionEnabled6 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                        isInteractionEnabled6 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled2)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width:67, height:33.5)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                isInteractionEnabled6 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                        isInteractionEnabled6 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled2)
                }
                
                if isFirstAppear3{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:67, height:33.5)
                        .position(switchPosition3)
                        .onTapGesture {
                            isFirstAppear3 = false
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                isInteractionEnabled6 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                        isInteractionEnabled6 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                }
                else if isSwitch3On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width:67, height:33.5)
                        .position(switchPosition3)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                isInteractionEnabled6 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                        isInteractionEnabled6 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled3)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width:67, height:33.5)
                        .position(switchPosition3)
                        .onTapGesture {
                            isSwitch3On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                isInteractionEnabled6 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                        isInteractionEnabled6 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled3)
                }
                
                if isFirstAppear4{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:67, height:33.5)
                        .position(switchPosition4)
                        .onTapGesture {
                            isFirstAppear4 = false
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                isInteractionEnabled6 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                        isInteractionEnabled6 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                }
                else if isSwitch4On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width:67, height:33.5)
                        .position(switchPosition4)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                isInteractionEnabled6 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                        isInteractionEnabled6 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled4)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width:67, height:33.5)
                        .position(switchPosition4)
                        .onTapGesture {
                            isSwitch4On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                isInteractionEnabled6 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                        isInteractionEnabled6 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled4)
                }
                
                if isFirstAppear5{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:67, height:33.5)
                        .position(switchPosition5)
                        .onTapGesture {
                            isFirstAppear5 = false
                            isSwitch5On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                isInteractionEnabled6 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                        isInteractionEnabled6 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled5)
                }
                else if isSwitch5On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width:67, height:33.5)
                        .position(switchPosition5)
                        .onTapGesture {
                            isSwitch5On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                isInteractionEnabled6 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                        isInteractionEnabled6 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled5)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width:67, height:33.5)
                        .position(switchPosition5)
                        .onTapGesture {
                            isSwitch5On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                isInteractionEnabled6 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                        isInteractionEnabled6 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled5)
                }
                
                if isFirstAppear6{
                    Image("Level Switch Off")
                        .resizable()
                        .frame(width:67, height:33.5)
                        .position(switchPosition6)
                        .onTapGesture {
                            isFirstAppear6 = false
                            isSwitch6On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                isInteractionEnabled6 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                        isInteractionEnabled6 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled6)
                }
                else if isSwitch6On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On")
                        .frame(width:67, height:33.5)
                        .position(switchPosition6)
                        .onTapGesture {
                            isSwitch6On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                isInteractionEnabled6 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                        isInteractionEnabled6 = false
                                    }
                                }
                            }
                            
                        }
                        .disabled(!isInteractionEnabled6)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off")
                        .frame(width:67, height:33.5)
                        .position(switchPosition6)
                        .onTapGesture {
                            isSwitch6On.toggle()
                            generateHapticFeedbackHeavy()
                            if (isSwitch3On || isSwitch4On) && !(isSwitch1On || isSwitch2On) && !(isSwitch5On && isSwitch6On) {
                                isInteractionEnabled1 = false
                                isInteractionEnabled2 = false
                                isInteractionEnabled3 = false
                                isInteractionEnabled4 = false
                                isInteractionEnabled5 = false
                                isInteractionEnabled6 = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showFinishedPage = true
                                        isInteractionEnabled1 = false
                                        isInteractionEnabled2 = false
                                        isInteractionEnabled3 = false
                                        isInteractionEnabled4 = false
                                        isInteractionEnabled5 = false
                                        isInteractionEnabled6 = false
                                    }
                                }
                            }
                        }
                        .disabled(!isInteractionEnabled6)
                }
                
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = false
                                isSwitch2On = false
                                isSwitch3On = false
                                isSwitch4On = false
                                isSwitch5On = false
                                isSwitch6On = false
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isFirstAppear3 = true
                                isFirstAppear4 = true
                                isFirstAppear5 = true
                                isFirstAppear6 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                                isInteractionEnabled3 = true
                                isInteractionEnabled4 = true
                                isInteractionEnabled5 = true
                                isInteractionEnabled6 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                navigateToLevel31 = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation {
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = false
                            isSwitch2On = false
                            isSwitch3On = false
                            isSwitch4On = false
                            isSwitch5On = false
                            isSwitch6On = false
                            isFirstAppear1 = true
                            isFirstAppear2 = true
                            isFirstAppear3 = true
                            isFirstAppear4 = true
                            isFirstAppear5 = true
                            isFirstAppear6 = true
                            isInteractionEnabled1 = true
                            isInteractionEnabled2 = true
                            isInteractionEnabled3 = true
                            isInteractionEnabled4 = true
                            isInteractionEnabled5 = true
                            isInteractionEnabled6 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToLevel31) {
                Level31View()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}

struct Level31View: View {
    @State private var isSwitch1On = false
    @State private var isSwitch2On = false
    @State private var showFinishedPage = false
    @State private var navigateToLevel32 = false
    @State private var navigateToSettings = false
    @State private var navigateToComponent = false
    @State private var showNavigationPage = false
    @State private var navigateToMenu = false
    @State private var isFirstAppear1 = true
    @State private var isFirstAppear2 = true
    @State private var infoAppear = false
    @State private var isInteractionEnabled1 = true
    @State private var isInteractionEnabled2 = true
    @EnvironmentObject var levelManager: LevelManager // 引入全局的 LevelManager
    @State private var bulb1On = false // 灯泡1的状态
    @State private var bulb2On = false // 灯泡2的状态
    @AppStorage("currentPage") var currentPage: Int = 0

    // 关卡难度自定义部分
        // 新增一个状态变量，用于跟踪进度
    // @State private var progress: CGFloat = 0.0 // 倒计时进度
        // 新增状态变量，用于跟踪步数和最大步数
    // @State private var currentSteps = 0
    // let maxSteps = Int(pow(2.0, 2.0)) // 2^2 = 4 步
    // let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect() // 定时器

    // 新增失败页面状态变量
    // @State private var showFailedPage = false

    @AppStorage("languageEnabled") var languageEnabled: Bool = false

    // 按钮位置
    let switchPosition = CGPoint(x: UIScreen.main.bounds.width / 8.50, y: UIScreen.main.bounds.height / 3.5)
    let switchPosition2 = CGPoint(x: UIScreen.main.bounds.width / 8.50, y: UIScreen.main.bounds.height / 3.5 + 229)
    // ------------------------------------------

    func generateHapticFeedbackHeavy() {
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        }
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }

    // 添加一个检查是否通关的函数
    func checkWinCondition() {
        if isSwitch1On && isSwitch2On {
            isInteractionEnabled1 = false
            isInteractionEnabled2 = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    levelManager.markLevelAsCompleted(level: 31) // 标记关卡为已完成
                    showFinishedPage = true
                    isInteractionEnabled1 = false
                    isInteractionEnabled2 = false
                }
            }
        }
    }

    // 更新后的检查状态函数
    func updateBulbs() {
        if isSwitch1On && !isSwitch2On {
            bulb1On = true
            bulb2On = false
        } else if !isSwitch1On && isSwitch2On {
            bulb1On = false
            bulb2On = true
        } else if !isSwitch1On && !isSwitch2On {
            // 当两个开关都关闭时，不改变灯泡状态，保持原有状态
        }
        else if isSwitch1On && isSwitch2On {
            bulb1On = true
            bulb2On = true
        }
    }


    var body: some View {
        NavigationStack {
            ZStack {
                let InfoScreenPosition = CGPoint(x: UIScreen.main.bounds.width / 1.92, y: UIScreen.main.bounds.height/1.8)
                
                Image("Main Page Background color")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width / 1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
                
                let PreviousButtonPosition = CGPoint(x: 105, y: 75)
                
                Button(action: {
                    navigateToComponent = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("Previous Button in Level Page")
                }
                .position(PreviousButtonPosition)
                
                if languageEnabled {
                    Image("Level31 Wire Chinese")
                        .position(x: switchPosition.x + 295, y: switchPosition.y+90)
                } else {
                    Image("Level31 Wire")
                        .position(x: switchPosition.x + 295, y: switchPosition.y+90)
                }
                
                Image("Bulb OFF")
                        .position(x: switchPosition.x+560, y: switchPosition.y+62)
                
                Image("Bulb ON")
                    .position(x: switchPosition.x+560, y: switchPosition.y+62)
                    .opacity(bulb1On ? 1 : 0) // 灯泡1的状态基于bulb1On变量
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: bulb1On)

                Image("Bulb OFF2")
                    .position(x: switchPosition.x+409, y: switchPosition.y+102)

                Image("Bulb ON2")
                    .position(x: switchPosition.x+409, y: switchPosition.y+72)
                    .opacity(bulb2On ? 1 : 0) // 灯泡2的状态基于bulb2On变量
                    .animation(Animation.easeIn(duration: 0.25).delay(0.1), value: bulb2On)
                
                
                if isFirstAppear1{
                    Image("Level Switch Off2")
                        .frame(width:124, height:62)
                        .position(switchPosition)
                        .onTapGesture {
                            isFirstAppear1 = false
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            checkWinCondition() // 检查是否过关
                            updateBulbs() // 更新灯泡状态
                        }
                }
                else if isSwitch1On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            checkWinCondition() // 检查是否过关
                            updateBulbs() // 更新灯泡状态
                        }
                        .disabled(!isInteractionEnabled1)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width: 124, height: 62)
                        .position(switchPosition)
                        .onTapGesture {
                            isSwitch1On.toggle()
                            generateHapticFeedbackHeavy()
                            checkWinCondition() // 检查是否过关
                            updateBulbs() // 更新灯泡状态
                        }
                        .disabled(!isInteractionEnabled1)
                }
                
                if isFirstAppear2{
                    Image("Level Switch Off2")
                        .frame(width:124, height:62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isFirstAppear2 = false
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            checkWinCondition() // 检查是否过关
                            updateBulbs() // 更新灯泡状态
                        }
                }
                else if isSwitch2On {
                    LottieAnimationViewContainer(filename: "Level Page Switch On2")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                            isSwitch2On.toggle()
                            generateHapticFeedbackHeavy()
                            checkWinCondition() // 检查是否过关
                            updateBulbs() // 更新灯泡状态
                        }
                        .disabled(!isInteractionEnabled2)
                } else {
                    LottieAnimationViewContainer(filename: "Level Page Switch Off2")
                        .frame(width: 124, height: 62)
                        .position(switchPosition2)
                        .onTapGesture {
                                isSwitch2On.toggle()
                                generateHapticFeedbackHeavy()
                                checkWinCondition() // 检查是否过关
                                updateBulbs() // 更新灯泡状态
                        }
                        .disabled(!isInteractionEnabled2)
                }
                

                let InfoButtonPosition = CGPoint(x: 175, y: 64)
                
                Button(action: {
                    infoAppear = true
                    generateHapticFeedbackMedium()
                }) {
                    Image("InfoButton")
                        .frame(width: 50, height: 50)
                }
                .position(InfoButtonPosition)
                
                if infoAppear {
                    if languageEnabled {
                        Image("Info Screen For SRLatch Chinese")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                    else {
                        Image("Info Screen For SRLatch")
                            .frame(width: 600, height: 300)
                            .position(InfoScreenPosition)
                            .animation(Animation.easeIn(duration: 10), value: infoAppear)
                    }
                        
                    Button(action: {
                        infoAppear = false
                        generateHapticFeedbackMedium()
                    }) {
                        Image("Cancel Button")
                            .frame(width: 50, height: 50)
                    }
                    .position(x: InfoScreenPosition.x + 275, y: InfoScreenPosition.y - 125)
                }
                
                
                if showFinishedPage {
                    FinishedPageView(
                        onBackToLevel: {
                            withAnimation {
                                showFinishedPage = false
                                isSwitch1On = false
                                isSwitch2On = false
                                isFirstAppear1 = true
                                isFirstAppear2 = true
                                isInteractionEnabled1 = true
                                isInteractionEnabled2 = true
                            }
                        },
                        onNextLevel: {
                            withAnimation {
                                // navigateToLevel32 = true
                                currentPage = 3
                                navigateToComponent = true
                            }
                        },
                        onBackToComponent: {
                            withAnimation {
                                navigateToComponent = true
                            }
                        }
                    )
                    .transition(.move(edge: .bottom))
                }

                
                let navPosition = CGPoint(x: UIScreen.main.bounds.width-60, y: 50)
                
                        Button(action: {
                            showNavigationPage = true
                            generateHapticFeedbackMedium()
                        }) {
                            Image("Navigation")
                                .frame(width: 50, height: 50)
                        }
                        .position(navPosition)
                
                if showNavigationPage {
                    NavigationPageView(
                        onBackToLevel: {
                            showNavigationPage = false
                            isSwitch1On = false
                            isSwitch2On = false
                            isFirstAppear1 = false
                            isFirstAppear2 = false
                            isInteractionEnabled1 = true
                            isInteractionEnabled2 = true
                        },
                        onNextLevel: {
                            showNavigationPage = false
                        },
                        onBackToComponent: {
                            showNavigationPage = false
                            navigateToMenu = true
                        },
                        onSettings: {
                            showNavigationPage = false
                            navigateToSettings = true
                        },
                        onPreviousToLevel: {
                            showNavigationPage = false
                            navigateToComponent = true
                        }
                    )
                    .transition(.move(edge: .bottom))
                }
                if navigateToSettings {
                                    SettingsView()
                                    Button(action: {
                                        navigateToSettings = false
                                        generateHapticFeedbackMedium()
                                    }) {
                                        Image("Cancel Button")
                                            .frame(width: 50, height: 50)
                                    }
                                    .position(x: InfoScreenPosition.x + 285, y: InfoScreenPosition.y - 125)
                                }
            }

            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToComponent) {
                ComponentsView()
            }
            .navigationDestination(isPresented: $navigateToMenu) {
                MenuView()
            }
            }
            .navigationBarHidden(true)
        }
}


struct DefaultLevelView: View {
    let level: Int
    
    var body: some View {
        VStack {
            Text("Level \(level) Page")
                .font(.largeTitle)
                .foregroundColor(.purple)
                .padding()
            
            Text("Default content for levels above 10")
        }
        .navigationTitle("Level \(level)")
    }
}

struct LottieAnimationViewContainer: UIViewRepresentable {
    var filename: String

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let animationView = LottieAnimationView(name: filename)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .playOnce
        view.addSubview(animationView)
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor),
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if let animationView = uiView.subviews.first as? LottieAnimationView {
            animationView.play()
        }
    }
}


struct FinishedPageView: View {
    var onBackToLevel: () -> Void
    var onNextLevel: () -> Void
    var onBackToComponent: () -> Void
    @AppStorage("languageEnabled") var languageEnabled: Bool = false
    
    func generateHapticFeedbackMedium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }


    var body: some View {
        ZStack {
            if languageEnabled {
                Image("Success page Chinese")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
            } else {
                Image("Success page")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .position(x: UIScreen.main.bounds.width/1.91, y: UIScreen.main.bounds.height/1.84)
                    .frame(width: UIScreen.main.bounds.width*1.03, height: UIScreen.main.bounds.height*1.03)
                    .edgesIgnoringSafeArea(.all)
            }
            
                LottieAnimationViewContainer(filename: "Confetti")
                    .frame(width: 700, height: 400)

                HStack(spacing: UIScreen.main.bounds.height/25) {
                    Button(action: {
                        generateHapticFeedbackMedium()
                        onBackToComponent()
                    }) {
                        Image("Back Button In Success Page")
                                .frame(width: UIScreen.main.bounds.width/10, height: UIScreen.main.bounds.height/10)
                    }
                    Button(action: {
                        generateHapticFeedbackMedium()
                        onBackToLevel()
                    }) {
                        Image("Retry Button In Success Page")
                            .frame(width: UIScreen.main.bounds.width/10, height: UIScreen.main.bounds.height/10)
                    }
                    Button(action: {
                        generateHapticFeedbackMedium()
                        onNextLevel()
                    }) {
                        Image("Next Button In Success Page")
                            .frame(width: UIScreen.main.bounds.width/10, height: UIScreen.main.bounds.height/10)
                    }
                }
                
                .position(x:UIScreen.main.bounds.width/1.91, y:UIScreen.main.bounds.height/1.35)
                
            
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LevelManager()) // make sure environment object has add into preview
}
