import Foundation
import UIKit
import SwiftUI
import OSLog

@MainActor
class BugReportManager: ObservableObject {
    static let shared = BugReportManager()
    
    @Published var isReportingBug = false
    
    private var userActions: [UserAction] = []
    private var logs: [LogEntry] = []
    private let maxActionsCount = 20
    private let maxLogsCount = 100
    
    // GitHub Configuration (共有パッケージ互換)
    private var gitHubToken: String?
    private var gitHubOwner: String?
    private var gitHubRepo: String?
    
    private init() {}
    
    // MARK: - Configuration (共有パッケージ互換)
    
    func configure(gitHubToken: String?, gitHubOwner: String?, gitHubRepo: String?) {
        self.gitHubToken = gitHubToken
        self.gitHubOwner = gitHubOwner
        self.gitHubRepo = gitHubRepo
        log(.info, "BugReportManager configured with GitHub settings", source: "BugReportManager")
    }
    
    private var hasValidTokens: Bool {
        return gitHubToken != nil && gitHubOwner != nil && gitHubRepo != nil
    }
    
    // MARK: - User Action Tracking
    
    func trackUserAction(_ action: String, viewName: String, details: [String: String]? = nil) {
        let userAction = UserAction(action: action, viewName: viewName, details: details)
        
        // Memory Leak対策・循環参照解消 (Issue #33)
        Task { @MainActor [weak self] in
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
        
        // Memory Leak対策・循環参照解消 (Issue #33)
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.logs.append(entry)
            
            // Keep only recent logs
            if self.logs.count > self.maxLogsCount {
                self.logs.removeFirst(self.logs.count - self.maxLogsCount)
            }
        }
        
        #if DEBUG
        Logger.debug.debug("[\(level.rawValue)] \(source ?? "App"): \(message)")
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
    
    func createBugReport(
        category: BugCategory,
        description: String? = nil,
        reproductionSteps: String? = nil,
        expectedBehavior: String? = nil,
        actualBehavior: String? = nil,
        currentView: String,
        screenshot: Data?
    ) -> BugReport {
        // スクリーンショット情報をログ出力
        if let screenshot = screenshot {
            log(.info, "Screenshot captured: \(screenshot.count) bytes", source: "BugReportManager")
        } else {
            log(.warning, "No screenshot provided", source: "BugReportManager")
        }
        
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
        // 設定確認（共有パッケージ互換）
        log(.info, "Environment check - GitHub Token: \(gitHubToken != nil ? "Set" : "Not set")")
        log(.info, "Environment check - GitHub Owner: \(gitHubOwner ?? "Not set")")
        log(.info, "Environment check - GitHub Repo: \(gitHubRepo ?? "Not set")")
        
        #if DEBUG
        // デバッグビルドでは、GitHubトークンがない場合はローカル保存
        if !hasValidTokens {
            // フォールバック: 環境変数からの取得を試行
            if !EnvironmentConfig.hasValidTokens {
                let validation = EnvironmentConfig.validateTokens()
                log(.warning, "GitHub token not configured: \(validation.message)")
                log(.warning, "Saving bug report locally instead.")
                try await saveLocally(report)
                return
            } else {
                // 環境変数設定で再設定
                configure(
                    gitHubToken: EnvironmentConfig.githubToken,
                    gitHubOwner: EnvironmentConfig.githubOwner,
                    gitHubRepo: EnvironmentConfig.githubRepo
                )
            }
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