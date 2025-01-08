//
//  XORApp.swift
//  XOR
//
//  Created by Annie Peng and Shawn Shao on 7/1/24.
//

import SwiftUI
import SwiftData

@main
struct XORApp: App {
    @AppStorage("musicEnabled") var musicEnabled: Bool = true
    @StateObject var levelManager = LevelManager() // 在这里实例化 LevelManager

    init() {
        if musicEnabled{
            AudioManager.shared.setupBackgroundMusic()
            AudioManager.shared.playBackgroundMusic()
        } else {
            AudioManager.shared.pauseBackgroundMusic()
        }
    }
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    AudioManager.shared.adjustMusicPlayback(isPlaying: musicEnabled)
                }
                .onChange(of: musicEnabled) {
                    AudioManager.shared.adjustMusicPlayback(isPlaying: musicEnabled)
                }
                .environmentObject(levelManager) // 将 LevelManager 注入到整个视图树中
        }
        .modelContainer(sharedModelContainer)
    }
}
