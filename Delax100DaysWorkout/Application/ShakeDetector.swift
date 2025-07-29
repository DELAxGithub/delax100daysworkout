import UIKit
import SwiftUI

// MARK: - Shake Detection Extension

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        #if DEBUG
        if motion == .motionShake {
            // バグ報告機能を優先し、デフォルトのUndo機能を無効化
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
            return  // superを呼ばないことでUndo機能を無効化
        }
        #endif
        // DEBUG以外の場合は通常のUndo機能を維持
        super.motionEnded(motion, with: event)
    }
}

extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

// MARK: - Shake Detector View Modifier

struct ShakeDetector: ViewModifier {
    @State private var showBugReport = false
    let currentView: String
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
                showBugReport = true
            }
            .sheet(isPresented: $showBugReport) {
                BugReportView(currentView: currentView)
            }
    }
}

extension View {
    func shakeDetector(currentView: String) -> some View {
        self.modifier(ShakeDetector(currentView: currentView))
    }
}

// MARK: - Debug Menu View

struct DebugMenuView: View {
    @Binding var isPresented: Bool
    let currentView: String
    
    var body: some View {
        NavigationView {
            List {
                Section("デバッグツール") {
                    Button {
                        BugReportManager.shared.showBugReportView()
                        isPresented = false
                    } label: {
                        Label("バグを報告", systemImage: "ladybug")
                    }
                    
                    Button {
                        // Clear all data
                    } label: {
                        Label("データをクリア", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                    
                    Button {
                        // Show logs
                    } label: {
                        Label("ログを表示", systemImage: "doc.text")
                    }
                }
                
                Section("情報") {
                    LabeledContent("現在の画面", value: currentView)
                    LabeledContent("バージョン", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                    LabeledContent("ビルド", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                }
                
                Section("環境変数") {
                    LabeledContent("GitHub Token") {
                        Text(EnvironmentConfig.githubToken != nil ? "✅ 設定済み" : "❌ 未設定")
                            .foregroundColor(EnvironmentConfig.githubToken != nil ? .green : .red)
                    }
                    LabeledContent("GitHub Owner", value: EnvironmentConfig.githubOwner)
                    LabeledContent("GitHub Repo", value: EnvironmentConfig.githubRepo)
                    LabeledContent("Claude API Key") {
                        Text(EnvironmentConfig.claudeAPIKey != nil ? "✅ 設定済み" : "❌ 未設定")
                            .foregroundColor(EnvironmentConfig.claudeAPIKey != nil ? .green : .red)
                    }
                    
                    Button {
                        let validation = EnvironmentConfig.validateTokens()
                        print("環境変数検証: \(validation.message)")
                    } label: {
                        Label("環境変数を検証", systemImage: "checkmark.circle")
                    }
                }
            }
            .navigationTitle("デバッグメニュー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

// MARK: - Debug Button Overlay

struct DebugButtonOverlay: ViewModifier {
    @State private var showDebugMenu = false
    let currentView: String
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomTrailing) {
                #if DEBUG
                Button {
                    showDebugMenu = true
                } label: {
                    Image(systemName: "ladybug.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .background(Color.orange)
                        .clipShape(Circle())
                        .shadow(radius: 4)
                }
                .padding()
                #endif
            }
            .sheet(isPresented: $showDebugMenu) {
                DebugMenuView(isPresented: $showDebugMenu, currentView: currentView)
            }
    }
}

extension View {
    func debugButton(currentView: String) -> some View {
        self.modifier(DebugButtonOverlay(currentView: currentView))
    }
}