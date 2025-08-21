import Foundation
import SwiftData

@Model
final class WeeklyTemplate: @unchecked Sendable {
    var name: String
    var isActive: Bool = false
    var createdAt: Date
    var updatedAt: Date
    var weekStartDate: Date = Date()
    var generatedBy: String?
    var notes: String?
    
    @Relationship(deleteRule: .cascade)
    var dailyTasks: [DailyTask] = []
    
    init(name: String, isActive: Bool = false) {
        self.name = name
        self.isActive = isActive
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func addTask(_ task: DailyTask) {
        task.template = self
        dailyTasks.append(task)
        updatedAt = Date()
    }
    
    func removeTask(_ task: DailyTask) {
        dailyTasks.removeAll { $0.id == task.id }
        updatedAt = Date()
    }
    
    func tasksForDay(_ dayOfWeek: Int) -> [DailyTask] {
        dailyTasks.filter { $0.dayOfWeek == dayOfWeek }
            .sorted { $0.sortOrder < $1.sortOrder }
    }
    
    func activate() {
        isActive = true
        updatedAt = Date()
    }
    
    func deactivate() {
        isActive = false
        updatedAt = Date()
    }
    
    // デフォルトテンプレートを作成
    static func createDefaultTemplate() -> WeeklyTemplate {
        let template = WeeklyTemplate(name: "基本プラン")
        
        // 日曜：リカバリー柔軟（30分）＋前後開脚記録
        let sundayFlex = DailyTask(
            dayOfWeek: 0,
            workoutType: .flexibility,
            title: "リカバリー柔軟",
            description: "30分＋前後開脚記録",
            targetDetails: {
                var details = TargetDetails()
                details.targetDuration = 30
                return details
            }()
        )
        template.addTask(sundayFlex)
        
        // 月曜：Push筋トレ＋ストレッチ10分
        let mondayStrength = DailyTask(
            dayOfWeek: 1,
            workoutType: .strength,
            title: "Push筋トレ",
            description: "胸・肩・三頭筋",
            targetDetails: {
                var details = TargetDetails()
                details.exercises = ["ベンチプレス", "ダンベルプレス", "ショルダープレス"]
                details.targetSets = 3
                details.targetReps = 10
                return details
            }()
        )
        template.addTask(mondayStrength)
        
        let mondayFlex = DailyTask(
            dayOfWeek: 1,
            workoutType: .flexibility,
            title: "ストレッチ",
            description: "筋トレ後のストレッチ",
            targetDetails: {
                var details = TargetDetails()
                details.targetDuration = 10
                return details
            }(),
            sortOrder: 1
        )
        template.addTask(mondayFlex)
        
        // 火曜：朝の柔軟（20分）＋前屈/左右開脚記録
        let tuesdayFlex = DailyTask(
            dayOfWeek: 2,
            workoutType: .flexibility,
            title: "朝の柔軟",
            description: "20分＋前屈/左右開脚記録",
            targetDetails: {
                var details = TargetDetails()
                details.targetDuration = 20
                details.targetForwardBend = 0
                details.targetSplitAngle = 120
                return details
            }()
        )
        template.addTask(tuesdayFlex)
        
        // 水曜：SST 45分（Week2/4はVO2max）
        let wednesdayBike = DailyTask(
            dayOfWeek: 3,
            workoutType: .cycling,
            title: "SST 45分",
            description: "Sweet Spot Training",
            targetDetails: {
                var details = TargetDetails()
                details.duration = 45
                details.intensity = .sst
                details.targetPower = 230
                return details
            }(),
            isFlexible: true
        )
        template.addTask(wednesdayBike)
        
        // 木曜：Pull筋トレ＋体幹トレ＋ストレッチ
        let thursdayStrength = DailyTask(
            dayOfWeek: 4,
            workoutType: .strength,
            title: "Pull筋トレ＋体幹",
            description: "背中・二頭筋・体幹",
            targetDetails: {
                var details = TargetDetails()
                details.exercises = ["プルアップ", "ラットプルダウン", "ローイング", "プランク"]
                details.targetSets = 3
                details.targetReps = 10
                return details
            }()
        )
        template.addTask(thursdayStrength)
        
        let thursdayFlex = DailyTask(
            dayOfWeek: 4,
            workoutType: .flexibility,
            title: "ストレッチ",
            description: "筋トレ後のストレッチ",
            targetDetails: {
                var details = TargetDetails()
                details.targetDuration = 10
                return details
            }(),
            sortOrder: 1
        )
        template.addTask(thursdayFlex)
        
        // 金曜：Z2脂肪燃焼ライド（45分）＋柔軟（前後）
        let fridayBike = DailyTask(
            dayOfWeek: 5,
            workoutType: .cycling,
            title: "Z2脂肪燃焼ライド",
            description: "45分の脂肪燃焼ライド",
            targetDetails: {
                var details = TargetDetails()
                details.duration = 45
                details.intensity = .z2
                details.targetPower = 170
                return details
            }()
        )
        template.addTask(fridayBike)
        
        let fridayFlex = DailyTask(
            dayOfWeek: 5,
            workoutType: .flexibility,
            title: "柔軟（前後）",
            description: "前後開脚中心",
            targetDetails: {
                var details = TargetDetails()
                details.targetDuration = 15
                return details
            }(),
            sortOrder: 1
        )
        template.addTask(fridayFlex)
        
        // 土曜：ロングライド（90〜120分）＋Legs/Core筋トレ
        let saturdayBike = DailyTask(
            dayOfWeek: 6,
            workoutType: .cycling,
            title: "ロングライド",
            description: "90〜120分の持久力向上",
            targetDetails: {
                var details = TargetDetails()
                details.duration = 90
                details.intensity = .z2
                details.targetPower = 180
                return details
            }(),
            isFlexible: true
        )
        template.addTask(saturdayBike)
        
        let saturdayStrength = DailyTask(
            dayOfWeek: 6,
            workoutType: .strength,
            title: "Legs+Core筋トレ",
            description: "脚・体幹",
            targetDetails: {
                var details = TargetDetails()
                details.exercises = ["スクワット", "ランジ", "デッドリフト", "腹筋"]
                details.targetSets = 3
                details.targetReps = 10
                return details
            }(),
            sortOrder: 1
        )
        template.addTask(saturdayStrength)
        
        return template
    }
}