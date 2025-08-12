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

extension FlexibilityDetail: ModelValidation {
    var validationErrors: [ValidationError] {
        validate().errors + validate().warnings
    }
    
    var isValid: Bool {
        validate().isValid
    }
    
    func validate() -> ValidationResult {
        var errors: [ValidationError] = []
        
        // 前屈距離の検証
        if forwardBendDistance < -50 {
            errors.append(ValidationError(
                field: "forwardBendDistance",
                message: "前屈距離は-50cm以上である必要があります",
                severity: .error
            ))
        } else if forwardBendDistance > 50 {
            errors.append(ValidationError(
                field: "forwardBendDistance",
                message: "前屈距離が50cmを超えています",
                severity: .warning
            ))
        }
        
        // 各種スプリット角度の検証
        let splitFields = [
            ("leftSplitAngle", leftSplitAngle, "左スプリット角度"),
            ("rightSplitAngle", rightSplitAngle, "右スプリット角度"),
            ("frontSplitAngle", frontSplitAngle, "前スプリット角度"),
            ("backSplitAngle", backSplitAngle, "後スプリット角度")
        ]
        
        for (field, angle, name) in splitFields {
            if angle < 0 {
                errors.append(ValidationError(
                    field: field,
                    message: "\(name)は0度以上である必要があります",
                    severity: .error
                ))
            } else if angle > 180 {
                errors.append(ValidationError(
                    field: field,
                    message: "\(name)は180度以下である必要があります",
                    severity: .error
                ))
            }
        }
        
        // オプショナルな角度の検証
        if let forwardLeft = forwardSplitLeft {
            if forwardLeft < 0 || forwardLeft > 180 {
                errors.append(ValidationError(
                    field: "forwardSplitLeft",
                    message: "前方左スプリットは0-180度の範囲である必要があります",
                    severity: .error
                ))
            }
        }
        
        if let forwardRight = forwardSplitRight {
            if forwardRight < 0 || forwardRight > 180 {
                errors.append(ValidationError(
                    field: "forwardSplitRight",
                    message: "前方右スプリットは0-180度の範囲である必要があります",
                    severity: .error
                ))
            }
        }
        
        if let bridge = backBridgeAngle {
            if bridge < 0 || bridge > 180 {
                errors.append(ValidationError(
                    field: "backBridgeAngle",
                    message: "ブリッジ角度は0-180度の範囲である必要があります",
                    severity: .error
                ))
            }
        }
        
        if let side = sideSplitAngle {
            if side < 0 || side > 180 {
                errors.append(ValidationError(
                    field: "sideSplitAngle",
                    message: "サイドスプリット角度は0-180度の範囲である必要があります",
                    severity: .error
                ))
            }
        }
        
        // 時間の検証
        if let durationError = ValidationRules.validateDuration(duration) {
            errors.append(durationError)
        }
        
        // ノートの検証
        if let notes = notes, notes.count > 500 {
            errors.append(ValidationError(
                field: "notes",
                message: "ノートは500文字以下にしてください",
                severity: .warning
            ))
        }
        
        // 論理的整合性チェック
        if leftSplitAngle > 0 && rightSplitAngle > 0 {
            let difference = abs(leftSplitAngle - rightSplitAngle)
            if difference > 30 {
                errors.append(ValidationError(
                    field: "splitBalance",
                    message: "左右のスプリット角度の差が30度を超えています。左右のバランスに注意してください",
                    severity: .warning
                ))
            }
        }
        
        return ValidationResult(errors: errors)
    }
}