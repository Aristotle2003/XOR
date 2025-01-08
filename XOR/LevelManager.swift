import SwiftUI

class LevelManager: ObservableObject {
    // 使用 40 个关卡
    @AppStorage("levelStars") private var levelStarsData: Data = try! JSONEncoder().encode([Bool](repeating: false, count: 40))

    // 用于访问关卡状态的布尔数组
    private var levelStars: [Bool] {
        get {
            (try? JSONDecoder().decode([Bool].self, from: levelStarsData)) ?? [Bool](repeating: false, count: 40)
        }
        set {
            if let encoded = try? JSONEncoder().encode(newValue) {
                levelStarsData = encoded
            }
        }
    }

    func markLevelAsCompleted(level: Int) {
        if level-1 < levelStars.count {
            var updatedStars = levelStars
            updatedStars[level-1] = true
            levelStars = updatedStars
        }
    }
    
    func hasStarForLevel(level: Int) -> Bool {
        return level < levelStars.count && levelStars[level]
    }

     // 新增：重置所有关卡状态的方法
    func resetAllStars() {
        levelStars = [Bool](repeating: false, count: 40) // 重置所有关卡状态为 false
    }
}
