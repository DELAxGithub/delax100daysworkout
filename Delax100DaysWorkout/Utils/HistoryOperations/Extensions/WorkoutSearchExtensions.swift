import Foundation

// MARK: - Workout Record Search Extension

extension WorkoutRecord: Searchable {
    var searchableText: String {
        var components = [
            summary,
            workoutType.rawValue,
            workoutType.description,
            searchFormattedDate,
            isCompleted ? "完了" : "未完了"
        ]
        
        // Add cycling details if available
        if let cyclingDetail = cyclingDetail {
            components.append(contentsOf: [
                cyclingDetail.formattedDistance,
                cyclingDetail.formattedDuration,
                cyclingDetail.formattedAveragePower,
                cyclingDetail.intensity.rawValue,
                cyclingDetail.intensity.description
            ])
            
            if let notes = cyclingDetail.notes, !notes.isEmpty {
                components.append(notes)
            }
        }
        
        // Add strength details if available
        if let strengthDetails = strengthDetails {
            for detail in strengthDetails {
                components.append(contentsOf: [
                    detail.exercise,
                    "\(detail.sets)セット",
                    "\(detail.reps)回",
                    "\(detail.weight)kg"
                ])
                
                if let notes = detail.notes, !notes.isEmpty {
                    components.append(notes)
                }
            }
        }
        
        // Add flexibility details if available
        if let flexDetail = flexibilityDetail {
            components.append(contentsOf: [
                "前屈\(flexDetail.forwardBendDistance)cm",
                "左開脚\(flexDetail.leftSplitAngle)°",
                "右開脚\(flexDetail.rightSplitAngle)°",
                "前後開脚前\(flexDetail.frontSplitAngle)°",
                "前後開脚後\(flexDetail.backSplitAngle)°",
                "\(flexDetail.duration)分間"
            ])
            
            if let notes = flexDetail.notes, !notes.isEmpty {
                components.append(notes)
            }
        }
        
        // Add pilates details if available
        if let pilatesDetail = pilatesDetail {
            components.append(contentsOf: [
                pilatesDetail.exerciseType,
                pilatesDetail.difficulty.rawValue,
                "\(pilatesDetail.duration)分間"
            ])
            
            if let reps = pilatesDetail.repetitions {
                components.append("\(reps)回")
            }
            
            if let holdTime = pilatesDetail.holdTime {
                components.append("ホールド\(holdTime)秒")
            }
            
            if let core = pilatesDetail.coreEngagement {
                components.append("コア強度\(String(format: "%.1f", core))")
            }
            
            if let posture = pilatesDetail.posturalAlignment {
                components.append("姿勢\(String(format: "%.1f", posture))")
            }
            
            if let breath = pilatesDetail.breathControl {
                components.append("呼吸\(String(format: "%.1f", breath))")
            }
            
            if let notes = pilatesDetail.notes, !notes.isEmpty {
                components.append(notes)
            }
        }
        
        // Add yoga details if available
        if let yogaDetail = yogaDetail {
            components.append(contentsOf: [
                yogaDetail.yogaStyle.rawValue,
                "\(yogaDetail.duration)分間"
            ])
            
            for pose in yogaDetail.poses {
                components.append(pose)
            }
            
            if let breathingTechnique = yogaDetail.breathingTechnique, !breathingTechnique.isEmpty {
                components.append(breathingTechnique)
            }
            
            if let flexibility = yogaDetail.flexibility {
                components.append("柔軟性\(String(format: "%.1f", flexibility))")
            }
            
            if let balance = yogaDetail.balance {
                components.append("バランス\(String(format: "%.1f", balance))")
            }
            
            if let mindfulness = yogaDetail.mindfulness {
                components.append("マインドフルネス\(String(format: "%.1f", mindfulness))")
            }
            
            if yogaDetail.meditation {
                components.append("瞑想")
            }
            
            if let notes = yogaDetail.notes, !notes.isEmpty {
                components.append(notes)
            }
        }
        
        return components.joined(separator: " ")
    }
    
    var searchableDate: Date {
        return date
    }
    
    var searchableValue: Double {
        // Return different values based on workout type for meaningful search
        switch workoutType {
        case .cycling:
            return cyclingDetail?.distance ?? 0.0
        case .strength:
            return Double(strengthDetails?.count ?? 0)
        case .flexibility:
            return flexibilityDetail?.forwardBendDistance ?? 0.0
        case .pilates:
            return pilatesDetail?.coreEngagement ?? (isCompleted ? 1.0 : 0.0)
        case .yoga:
            return yogaDetail?.mindfulness ?? (isCompleted ? 1.0 : 0.0)
        }
    }
    
    private var searchFormattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - WorkoutType Description Extension

private extension WorkoutType {
    var description: String {
        switch self {
        case .cycling: return "サイクリング"
        case .strength: return "筋力トレーニング"
        case .flexibility: return "柔軟性"
        case .pilates: return "ピラティス"
        case .yoga: return "ヨガ"
        }
    }
}