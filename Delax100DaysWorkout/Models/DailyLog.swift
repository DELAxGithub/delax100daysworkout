import Foundation
import SwiftData
import OSLog

@Model
final class DailyLog {
    var date: Date
    var weightKg: Double
    
    init(date: Date, weightKg: Double) {
        // Validation
        guard weightKg > 0 && weightKg < 1000 else {
            Logger.error.error("Invalid weight value: \(weightKg)")
            self.date = date
            self.weightKg = 70.0 // Default fallback
            return
        }
        
        self.date = date
        self.weightKg = weightKg
    }
    
    // Validation method
    func isValid() -> Bool {
        return weightKg > 0 && weightKg < 1000
    }
}