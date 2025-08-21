import Foundation
import HealthKit

// HealthKit認証情報を格納する構造体
struct HealthKitAuthorizationInfo {
    let overallStatus: HKAuthorizationStatus
    let typeStatuses: [HKObjectType: HKAuthorizationStatus]
    let healthDataAvailable: Bool
    
    init(overallStatus: HKAuthorizationStatus, typeStatuses: [HKObjectType: HKAuthorizationStatus] = [:], healthDataAvailable: Bool = true) {
        self.overallStatus = overallStatus
        self.typeStatuses = typeStatuses
        self.healthDataAvailable = healthDataAvailable
    }
    
    // 各データタイプの認証状況
    var bodyMassStatus: HKAuthorizationStatus {
        guard let type = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return .notDetermined }
        return typeStatuses[type] ?? .notDetermined
    }
    
    var heartRateStatus: HKAuthorizationStatus {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRate) else { return .notDetermined }
        return typeStatuses[type] ?? .notDetermined
    }
    
    var cyclingPowerStatus: HKAuthorizationStatus {
        guard let type = HKObjectType.quantityType(forIdentifier: .cyclingPower) else { return .notDetermined }
        return typeStatuses[type] ?? .notDetermined
    }
    
    var activeEnergyStatus: HKAuthorizationStatus {
        guard let type = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return .notDetermined }
        return typeStatuses[type] ?? .notDetermined
    }
    
    var workoutStatus: HKAuthorizationStatus {
        let type = HKObjectType.workoutType()
        return typeStatuses[type] ?? .notDetermined
    }
    
    static let notAvailable = HealthKitAuthorizationInfo(
        overallStatus: .notDetermined,
        healthDataAvailable: false
    )
}