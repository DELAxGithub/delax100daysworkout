import Foundation
import SwiftData

@MainActor
class DataCacheManager: ObservableObject {
    static let shared = DataCacheManager()
    
    private var userProfileCache: UserProfile?
    private var userProfileCacheTimestamp: Date?
    
    private var dailyLogCache: [DailyLog] = []
    private var dailyLogCacheTimestamp: Date?
    
    private var workoutRecordsCache: [WorkoutRecord] = []
    private var workoutRecordsCacheTimestamp: Date?
    
    private var weeklyTemplateCache: WeeklyTemplate?
    private var weeklyTemplateCacheTimestamp: Date?
    
    private let shortCacheDuration: TimeInterval = 60
    private let mediumCacheDuration: TimeInterval = 300
    private let longCacheDuration: TimeInterval = 900
    
    private init() {}
    
    func getUserProfile(from context: ModelContext, forceRefresh: Bool = false) -> UserProfile? {
        if !forceRefresh,
           let cached = userProfileCache,
           let timestamp = userProfileCacheTimestamp,
           Date().timeIntervalSince(timestamp) < longCacheDuration {
            return cached
        }
        
        let descriptor = FetchDescriptor<UserProfile>()
        if let profile = try? context.fetch(descriptor).first {
            userProfileCache = profile
            userProfileCacheTimestamp = Date()
            return profile
        }
        
        return nil
    }
    
    func getLatestDailyLog(from context: ModelContext, forceRefresh: Bool = false) -> DailyLog? {
        if !forceRefresh,
           let timestamp = dailyLogCacheTimestamp,
           Date().timeIntervalSince(timestamp) < mediumCacheDuration,
           !dailyLogCache.isEmpty {
            return dailyLogCache.first
        }
        
        var descriptor = FetchDescriptor<DailyLog>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        
        if let logs = try? context.fetch(descriptor) {
            dailyLogCache = logs
            dailyLogCacheTimestamp = Date()
            return logs.first
        }
        
        return nil
    }
    
    func getRecentWorkoutRecords(
        from context: ModelContext,
        limit: Int = 30,
        forceRefresh: Bool = false
    ) -> [WorkoutRecord] {
        if !forceRefresh,
           let timestamp = workoutRecordsCacheTimestamp,
           Date().timeIntervalSince(timestamp) < shortCacheDuration,
           !workoutRecordsCache.isEmpty {
            return Array(workoutRecordsCache.prefix(limit))
        }
        
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 3600)
        var descriptor = FetchDescriptor<WorkoutRecord>(
            predicate: #Predicate { record in
                record.date >= thirtyDaysAgo
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        if let records = try? context.fetch(descriptor) {
            workoutRecordsCache = records
            workoutRecordsCacheTimestamp = Date()
            return records
        }
        
        return []
    }
    
    func getActiveWeeklyTemplate(from context: ModelContext, forceRefresh: Bool = false) -> WeeklyTemplate? {
        if !forceRefresh,
           let cached = weeklyTemplateCache,
           let timestamp = weeklyTemplateCacheTimestamp,
           Date().timeIntervalSince(timestamp) < mediumCacheDuration {
            return cached
        }
        
        let descriptor = FetchDescriptor<WeeklyTemplate>(
            predicate: #Predicate { template in
                template.isActive == true
            },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        
        if let template = try? context.fetch(descriptor).first {
            weeklyTemplateCache = template
            weeklyTemplateCacheTimestamp = Date()
            return template
        }
        
        return nil
    }
    
    func batchFetchDashboardData(from context: ModelContext) async -> (
        profile: UserProfile?,
        latestLog: DailyLog?,
        recentRecords: [WorkoutRecord],
        activeTemplate: WeeklyTemplate?
    ) {
        async let profile = Task { @MainActor in
            getUserProfile(from: context)
        }.value
        
        async let log = Task { @MainActor in
            getLatestDailyLog(from: context)
        }.value
        
        async let records = Task { @MainActor in
            getRecentWorkoutRecords(from: context, limit: 7)
        }.value
        
        async let template = Task { @MainActor in
            getActiveWeeklyTemplate(from: context)
        }.value
        
        return await (profile, log, records, template)
    }
    
    func invalidateCache(for type: CacheType? = nil) {
        if let type = type {
            switch type {
            case .userProfile:
                userProfileCache = nil
                userProfileCacheTimestamp = nil
            case .dailyLog:
                dailyLogCache = []
                dailyLogCacheTimestamp = nil
            case .workoutRecords:
                workoutRecordsCache = []
                workoutRecordsCacheTimestamp = nil
            case .weeklyTemplate:
                weeklyTemplateCache = nil
                weeklyTemplateCacheTimestamp = nil
            }
        } else {
            userProfileCache = nil
            userProfileCacheTimestamp = nil
            dailyLogCache = []
            dailyLogCacheTimestamp = nil
            workoutRecordsCache = []
            workoutRecordsCacheTimestamp = nil
            weeklyTemplateCache = nil
            weeklyTemplateCacheTimestamp = nil
        }
    }
    
    enum CacheType {
        case userProfile
        case dailyLog
        case workoutRecords
        case weeklyTemplate
    }
}