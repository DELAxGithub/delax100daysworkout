import Foundation
import UIKit
import SwiftUI

class BugReportManager: ObservableObject {
    static let shared = BugReportManager()
    
    @Published var isReportingBug = false
    
    private var userActions: [UserAction] = []
    private var logs: [LogEntry] = []
    private let maxActionsCount = 20
    private let maxLogsCount = 100
    
    private init() {}
    
    // MARK: - User Action Tracking
    
    func trackUserAction(_ action: String, viewName: String, details: [String: String]? = nil) {
        let userAction = UserAction(action: action, viewName: viewName, details: details)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.userActions.append(userAction)
            
            // Keep only recent actions
            if self.userActions.count > self.maxActionsCount {
                self.userActions.removeFirst(self.userActions.count - self.maxActionsCount)
            }
        }
    }
    
    // MARK: - Logging
    
    func log(_ level: LogLevel, _ message: String, source: String? = nil) {
        let entry = LogEntry(level: level, message: message, source: source)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.logs.append(entry)
            
            // Keep only recent logs
            if self.logs.count > self.maxLogsCount {
                self.logs.removeFirst(self.logs.count - self.maxLogsCount)
            }
        }
        
        #if DEBUG
        print("[\(level.rawValue)] \(source ?? "App"): \(message)")
        #endif
    }
    
    // MARK: - Bug Report Creation
    
    func captureBugReport(
        category: BugCategory,
        description: String? = nil,
        reproductionSteps: String? = nil,
        expectedBehavior: String? = nil,
        actualBehavior: String? = nil,
        currentView: String
    ) -> BugReport {
        // Capture screenshot
        let screenshot = captureScreenshot()
        
        // Get recent actions and logs
        let recentActions = Array(userActions.suffix(10))
        let recentLogs = logs.filter { log in
            log.level == .warning || log.level == .error
        }.suffix(20)
        
        return BugReport(
            category: category,
            description: description,
            reproductionSteps: reproductionSteps,
            expectedBehavior: expectedBehavior,
            actualBehavior: actualBehavior,
            screenshot: screenshot,
            currentView: currentView,
            userActions: recentActions,
            logs: Array(recentLogs)
        )
    }
    
    // MARK: - Screenshot Capture
    
    private func captureScreenshot() -> Data? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return nil }
        
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        let image = renderer.image { context in
            window.layer.render(in: context.cgContext)
        }
        
        return image.jpegData(compressionQuality: 0.8)
    }
    
    // MARK: - GitHub Issue Submission
    
    func submitBugReport(_ report: BugReport) async throws {
        // 環境変数の状態をログ出力
        log(.info, "Environment check - GitHub Token: \(EnvironmentConfig.githubToken != nil ? "Set" : "Not set")")
        log(.info, "Environment check - GitHub Owner: \(EnvironmentConfig.githubOwner)")
        log(.info, "Environment check - GitHub Repo: \(EnvironmentConfig.githubRepo)")
        
        #if DEBUG
        // デバッグビルドでは、GitHubトークンがない場合はローカル保存
        if !EnvironmentConfig.hasValidTokens {
            let validation = EnvironmentConfig.validateTokens()
            log(.warning, "GitHub token not configured: \(validation.message)")
            log(.warning, "Saving bug report locally instead.")
            try await saveLocally(report)
            return
        }
        #endif
        
        // GitHub APIを使用してIssueを作成
        log(.info, "Attempting to create GitHub Issue...")
        let gitHubService = GitHubService()
        do {
            let issue = try await gitHubService.createIssue(from: report)
            log(.info, "GitHub Issue created successfully: #\(issue.number) - \(issue.htmlUrl)")
            
            // 成功をユーザーに通知（実際の実装では通知を送信）
            DispatchQueue.main.async {
                // UserDefaults などに保存して、後で通知を表示
                UserDefaults.standard.set(issue.htmlUrl, forKey: "lastCreatedIssueUrl")
            }
        } catch {
            log(.error, "Failed to create GitHub Issue: \(error)")
            log(.error, "Error details: \(error.localizedDescription)")
            
            // フォールバック: ローカルに保存
            try await saveLocally(report)
            throw error
        }
    }
    
    private func saveLocally(_ report: BugReport) async throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(report)
        
        // Save to documents directory
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let filePath = documentsPath.appendingPathComponent("bug_report_\(report.id.uuidString).json")
        
        try data.write(to: filePath)
        
        log(.info, "Bug report saved locally to: \(filePath.path)")
    }
    
    // MARK: - Shake Detection Support
    
    func showBugReportView() {
        DispatchQueue.main.async {
            self.isReportingBug = true
        }
    }
}

// MARK: - Convenience Methods

extension BugReportManager {
    func trackButtonTap(_ buttonName: String, in viewName: String) {
        trackUserAction("Button Tap", viewName: viewName, details: ["button": buttonName])
    }
    
    func trackNavigation(to viewName: String, from previousView: String? = nil) {
        var details: [String: String] = [:]
        if let previousView = previousView {
            details["from"] = previousView
        }
        trackUserAction("Navigation", viewName: viewName, details: details)
    }
    
    func trackError(_ error: Error, in viewName: String) {
        log(.error, error.localizedDescription, source: viewName)
        trackUserAction("Error Occurred", viewName: viewName, details: ["error": error.localizedDescription])
    }
}