import Foundation
import SwiftData
import Combine
import OSLog

// MARK: - Protocol-Based Weekly Plan Manager

@MainActor
final class ProtocolBasedWeeklyPlanManager: ObservableObject, WeeklyPlanManaging {
    
    @Injected(ModelContextProviding.self) private var contextProvider: ModelContextProviding
    @Injected(ErrorHandling.self) private var errorHandler: ErrorHandling
    @Injected(AnalyticsProviding.self) private var analytics: AnalyticsProviding
    
    private let progressAnalyzer: ProgressAnalyzer
    private let aiService: WeeklyPlanAIService
    private let logger = Logger(subsystem: "Delax100DaysWorkout", category: "WeeklyPlanManager")
    
    @Published var updateStatus: PlanUpdateStatus = .idle
    @Published var lastUpdateDate: Date?
    @Published var lastUpdateHistory: PlanUpdateHistoryInfo?
    
    // Analysis statistics
    @Published var analysisCount: Int = 0
    @Published var lastAnalysisResult: String?
    @Published var lastAnalysisDataCount: Int = 0
    @Published var monthlyAnalysisCount: Int = 0
    
    // Settings
    @Published var autoUpdateEnabled: Bool = true
    @Published var maxCostPerUpdate: Double = 1.00
    @Published var updateFrequency: TimeInterval = 7 * 24 * 60 * 60 // 1 week
    
    // MARK: - Initialization
    
    init(container: DIContainer = DIContainer.shared) {
        // Dependencies injected via @Injected
        self.progressAnalyzer = ProgressAnalyzer(modelContext: contextProvider.modelContext)
        self.aiService = WeeklyPlanAIService()
        
        loadSettings()
        analytics.trackEvent("WeeklyPlanManager_Initialized", parameters: [:])
    }
    
    /// Manual dependency injection for testing
    init(
        contextProvider: ModelContextProviding,
        errorHandler: ErrorHandling,
        analytics: AnalyticsProviding
    ) {
        // Override injected dependencies
        DIContainer.shared.register(ModelContextProviding.self, instance: contextProvider)
        DIContainer.shared.register(ErrorHandling.self, instance: errorHandler)
        DIContainer.shared.register(AnalyticsProviding.self, instance: analytics)
        
        self.progressAnalyzer = ProgressAnalyzer(modelContext: contextProvider.modelContext)
        self.aiService = WeeklyPlanAIService()
        
        loadSettings()
    }
    
    // MARK: - WeeklyPlanManaging Protocol Implementation
    
    func generateWeeklyPlan(for profile: UserProfile) async -> WeeklyTemplate? {
        analytics.trackEvent("WeeklyPlan_GenerationStarted", parameters: ["profileId": profile.id.uuidString])
        
        updateStatus = .analyzing
        
        do {
            // Analyze progress data
            let analysisData = await progressAnalyzer.performFullAnalysis()
            analysisCount += 1
            lastAnalysisDataCount = analysisData.workoutRecords.count
            
            // Generate AI-powered plan
            let aiPrompt = await buildAnalysisPrompt(from: analysisData, profile: profile)
            let planResponse = await aiService.generateWeeklyPlan(prompt: aiPrompt)
            
            // Create and save template
            let template = await createTemplateFromResponse(planResponse, profile: profile)
            
            if let template = template {
                let success = await savePlan(template)
                if success {
                    updateStatus = .completed
                    lastUpdateDate = Date()
                    lastAnalysisResult = "Plan generated successfully"
                    
                    analytics.trackEvent("WeeklyPlan_GenerationCompleted", parameters: [
                        "profileId": profile.id.uuidString,
                        "dataPoints": lastAnalysisDataCount
                    ])
                    
                    return template
                }
            }
            
            throw WeeklyPlanError.planGenerationFailed
            
        } catch {
            updateStatus = .failed(error)
            errorHandler.handleValidationError(error, context: "generateWeeklyPlan")
            analytics.trackError(error, context: "WeeklyPlan_Generation")
            logger.error("Weekly plan generation failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    func updateWeeklyPlan(_ template: WeeklyTemplate) async -> Bool {
        analytics.trackEvent("WeeklyPlan_UpdateStarted", parameters: ["templateId": template.id.uuidString])
        
        do {
            contextProvider.modelContext.insert(template)
            try contextProvider.modelContext.save()
            
            analytics.trackEvent("WeeklyPlan_UpdateCompleted", parameters: ["templateId": template.id.uuidString])
            return true
            
        } catch {
            errorHandler.handleSwiftDataError(error, context: "updateWeeklyPlan")
            analytics.trackError(error, context: "WeeklyPlan_Update")
            logger.error("Failed to update weekly plan: \(error.localizedDescription)")
            return false
        }
    }
    
    func getCurrentWeekPlan() async -> WeeklyTemplate? {
        do {
            let calendar = Calendar.current
            let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            
            let descriptor = FetchDescriptor<WeeklyTemplate>(
                predicate: #Predicate<WeeklyTemplate> { template in
                    template.weekStartDate >= startOfWeek
                },
                sortBy: [SortDescriptor(\.weekStartDate, order: .reverse)]
            )
            
            descriptor.fetchLimit = 1
            let results = try contextProvider.modelContext.fetch(descriptor)
            
            analytics.trackEvent("WeeklyPlan_CurrentPlanFetched", parameters: [
                "found": !results.isEmpty
            ])
            
            return results.first
            
        } catch {
            errorHandler.handleSwiftDataError(error, context: "getCurrentWeekPlan")
            analytics.trackError(error, context: "WeeklyPlan_CurrentPlanFetch")
            logger.error("Failed to fetch current week plan: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - Additional Public Methods
    
    func shouldAutoUpdate() async -> Bool {
        guard autoUpdateEnabled else { return false }
        
        guard let lastUpdate = lastUpdateDate else { return true }
        
        let timeSinceLastUpdate = Date().timeIntervalSince(lastUpdate)
        return timeSinceLastUpdate >= updateFrequency
    }
    
    func performAutoUpdateIfNeeded(for profile: UserProfile) async {
        let shouldUpdate = await shouldAutoUpdate()
        
        if shouldUpdate {
            analytics.trackEvent("WeeklyPlan_AutoUpdateTriggered", parameters: [:])
            _ = await generateWeeklyPlan(for: profile)
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func loadSettings() {
        // Load user settings from UserDefaults or database
        autoUpdateEnabled = UserDefaults.standard.bool(forKey: "weeklyPlan.autoUpdateEnabled")
        maxCostPerUpdate = UserDefaults.standard.double(forKey: "weeklyPlan.maxCostPerUpdate")
        updateFrequency = UserDefaults.standard.double(forKey: "weeklyPlan.updateFrequency")
        
        // Set defaults if not previously set
        if maxCostPerUpdate == 0 {
            maxCostPerUpdate = 1.00
        }
        if updateFrequency == 0 {
            updateFrequency = 7 * 24 * 60 * 60 // 1 week
        }
    }
    
    private func buildAnalysisPrompt(from data: AnalysisData, profile: UserProfile) async -> String {
        // Build AI prompt based on analysis data and user profile
        // This is a simplified version - full implementation would be more complex
        return """
        Generate a weekly training plan based on the following analysis:
        
        User Profile: \(profile.name ?? "User")
        Current Goals: \(profile.goals ?? "General fitness")
        
        Recent Performance Data:
        - Workout Records: \(data.workoutRecords.count)
        - Completion Rate: \(data.completionRate)%
        - Progress Trends: \(data.progressTrends)
        
        Please provide a balanced weekly plan considering the user's progress and goals.
        """
    }
    
    private func createTemplateFromResponse(_ response: String, profile: UserProfile) async -> WeeklyTemplate? {
        // Parse AI response and create WeeklyTemplate
        // This is a simplified implementation
        let template = WeeklyTemplate()
        template.weekStartDate = Calendar.current.startOfDay(for: Date())
        template.generatedBy = "AI Assistant"
        template.notes = response
        
        return template
    }
    
    private func savePlan(_ template: WeeklyTemplate) async -> Bool {
        return await updateWeeklyPlan(template)
    }
}

// MARK: - Injectable Conformance

extension ProtocolBasedWeeklyPlanManager: Injectable {
    convenience init(container: DIContainer) {
        self.init(container: container)
    }
}

// MARK: - Supporting Types

enum WeeklyPlanError: Error, LocalizedError {
    case planGenerationFailed
    case invalidUserProfile
    case insufficientData
    case aiServiceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .planGenerationFailed:
            return "Failed to generate weekly plan"
        case .invalidUserProfile:
            return "Invalid user profile"
        case .insufficientData:
            return "Insufficient data for plan generation"
        case .aiServiceUnavailable:
            return "AI service unavailable"
        }
    }
}

struct AnalysisData {
    let workoutRecords: [WorkoutRecord]
    let completionRate: Double
    let progressTrends: String
}

struct PlanUpdateHistoryInfo {
    let date: Date
    let status: PlanUpdateStatus
    let dataPointsUsed: Int
    let resultSummary: String
}

// Re-export the existing enum for compatibility
enum PlanUpdateStatus: Equatable {
    case idle
    case analyzing
    case completed
    case failed(Error)
    
    static func == (lhs: PlanUpdateStatus, rhs: PlanUpdateStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.analyzing, .analyzing), (.completed, .completed):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}