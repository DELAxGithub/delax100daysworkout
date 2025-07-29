import Foundation
import SwiftData

@Model
final class DailyLog {
    var date: Date
    var weightKg: Double
    
    init(date: Date, weightKg: Double) {
        self.date = date
        self.weightKg = weightKg
    }
}