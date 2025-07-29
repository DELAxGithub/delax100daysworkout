import Foundation
import SwiftData

@Model
final class FlexibilityDetail {
    var forwardBendDistance: Double
    var leftSplitAngle: Double
    var rightSplitAngle: Double
    var frontSplitAngle: Double
    var backSplitAngle: Double
    var notes: String?
    var duration: Int
    
    init(forwardBendDistance: Double = 0, leftSplitAngle: Double = 0, rightSplitAngle: Double = 0, 
         frontSplitAngle: Double = 0, backSplitAngle: Double = 0, duration: Int = 0, notes: String? = nil) {
        self.forwardBendDistance = forwardBendDistance
        self.leftSplitAngle = leftSplitAngle
        self.rightSplitAngle = rightSplitAngle
        self.frontSplitAngle = frontSplitAngle
        self.backSplitAngle = backSplitAngle
        self.duration = duration
        self.notes = notes
    }
    
    var averageSplitAngle: Double {
        (leftSplitAngle + rightSplitAngle) / 2
    }
    
    var averageFrontBackSplit: Double {
        (frontSplitAngle + backSplitAngle) / 2
    }
}