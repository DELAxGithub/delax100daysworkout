import SwiftUI

struct CredentialSettingsView: View {
    @State private var githubToken: String = ""
    @State private var claudeAPIKey: String = ""
    @State private var showGitHubToken = false
    @State private var showClaudeAPIKey = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("GitHub認証情報")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GitHub Personal Access Token")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            if showGitHubToken {
                                TextField("ghp_...", text: $githubToken)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            } else {
                                SecureField("ghp_...", text: $githubToken)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                            
                            Button(action: {
                                showGitHubToken.toggle()
                            }) {
                                Image(systemName: showGitHubToken ? "eye.slash" : "eye")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Text("Issueの作成とバグレポート機能に必要です")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("GitHub Tokenを保存") {
                        saveGitHubToken()
                    }
                    .disabled(githubToken.isEmpty)
                }
                
                Section(header: Text("Claude AI認証情報")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Claude API Key")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            if showClaudeAPIKey {
                                TextField("sk-ant-...", text: $claudeAPIKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            } else {
                                SecureField("sk-ant-...", text: $claudeAPIKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                            }
                            
                            Button(action: {
                                showClaudeAPIKey.toggle()
                            }) {
                                Image(systemName: showClaudeAPIKey ? "eye.slash" : "eye")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        Text("AIによる自動修正機能に必要です（オプション）")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Claude API Keyを保存") {
                        saveClaudeAPIKey()
                    }
                    .disabled(claudeAPIKey.isEmpty)
                }
                
                Section(header: Text("セキュリティ情報")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("すべての認証情報はiOS Keychainに安全に保存されます", systemImage: "lock.shield")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Label("認証情報はデバイス上でのみ暗号化され、外部に送信されません", systemImage: "lock.icloud")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Label("アプリケーションをアンインストールすると認証情報も削除されます", systemImage: "trash.circle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        clearAllCredentials()
                    } label: {
                        Text("すべての認証情報を削除")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("認証情報設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadExistingCredentials()
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func loadExistingCredentials() {
        // Load masked versions of existing credentials for display
        if let _ = EnvironmentConfig.githubToken {
            githubToken = ""  // Don't display actual token
        }
        if let _ = EnvironmentConfig.claudeAPIKey {
            claudeAPIKey = ""  // Don't display actual key
        }
    }
    
    private func saveGitHubToken() {
        do {
            try EnvironmentConfig.setGitHubToken(githubToken)
            alertTitle = "成功"
            alertMessage = "GitHub Tokenが安全に保存されました"
            showAlert = true
            githubToken = ""  // Clear field after saving
        } catch {
            alertTitle = "エラー"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func saveClaudeAPIKey() {
        do {
            try EnvironmentConfig.setClaudeAPIKey(claudeAPIKey)
            alertTitle = "成功"
            alertMessage = "Claude API Keyが安全に保存されました"
            showAlert = true
            claudeAPIKey = ""  // Clear field after saving
        } catch {
            alertTitle = "エラー"
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }
    
    private func clearAllCredentials() {
        EnvironmentConfig.clearAllCredentials()
        githubToken = ""
        claudeAPIKey = ""
        alertTitle = "削除完了"
        alertMessage = "すべての認証情報が削除されました"
        showAlert = true
    }
}

#Preview {
    CredentialSettingsView()
}