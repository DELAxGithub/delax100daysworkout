import Foundation
import SwiftData

@Model
final class FlexibilityDetail {
    var forwardBendDistance: Double
    var leftSplitAngle: Double
    var rightSplitAngle: Double
    var frontSplitAngle: Double
    var backSplitAngle: Double
    var forwardSplitLeft: Double?
    var forwardSplitRight: Double?
    var backBridgeAngle: Double?
    var sideSplitAngle: Double?
    var notes: String?
    var duration: Int
    
    init(forwardBendDistance: Double = 0, leftSplitAngle: Double = 0, rightSplitAngle: Double = 0, 
         frontSplitAngle: Double = 0, backSplitAngle: Double = 0, forwardSplitLeft: Double? = nil,
         forwardSplitRight: Double? = nil, backBridgeAngle: Double? = nil, sideSplitAngle: Double? = nil, duration: Int = 0, notes: String? = nil) {
        self.forwardBendDistance = forwardBendDistance
        self.leftSplitAngle = leftSplitAngle
        self.rightSplitAngle = rightSplitAngle
        self.frontSplitAngle = frontSplitAngle
        self.backSplitAngle = backSplitAngle
        self.forwardSplitLeft = forwardSplitLeft
        self.forwardSplitRight = forwardSplitRight
        self.backBridgeAngle = backBridgeAngle
        self.sideSplitAngle = sideSplitAngle
        self.duration = duration
        self.notes = notes
    }
    
    var averageSplitAngle: Double {
        (leftSplitAngle + rightSplitAngle) / 2
    }
    
    var averageFrontBackSplit: Double {
        (frontSplitAngle + backSplitAngle) / 2
    }
    
    // MARK: - 新規追加プロパティのヘルパー
    
    /// 前屈スプリット平均（新規プロパティ）
    var averageForwardSplit: Double {
        let left = forwardSplitLeft ?? 0
        let right = forwardSplitRight ?? 0
        return (left + right) / 2
    }
    
    /// サイドスプリット角度（nil安全）
    var safeSideSplitAngle: Double {
        return sideSplitAngle ?? 0
    }
    
    /// ブリッジ角度（nil安全）
    var safeBackBridgeAngle: Double {
        return backBridgeAngle ?? 0
    }
}