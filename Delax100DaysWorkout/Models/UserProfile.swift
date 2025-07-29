import Foundation
import SwiftData

@Model
final class UserProfile {
    // A unique identifier, although for a single-user app, we'll likely only have one instance.
    @Attribute(.unique) var id: UUID
    
    // Goal Tracking
    var goalDate: Date
    
    // Weight Goals (in kilograms)
    var startWeightKg: Double
    var goalWeightKg: Double
    
    // Cycling FTP (Functional Threshold Power) Goals
    var startFtp: Int
    var goalFtp: Int
    
    init(id: UUID = UUID(), goalDate: Date = Date().addingTimeInterval(100 * 24 * 60 * 60), startWeightKg: Double = 0.0, goalWeightKg: Double = 0.0, startFtp: Int = 0, goalFtp: Int = 0) {
        self.id = id
        self.goalDate = goalDate
        self.startWeightKg = startWeightKg
        self.goalWeightKg = goalWeightKg
        self.startFtp = startFtp
        self.goalFtp = goalFtp
    }
}