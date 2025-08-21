import SwiftUI

struct ClaudeApiSection: View {
    @Binding var viewModel: SettingsViewModel
    
    var body: some View {
        Section(header: Text("Claude API設定")) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("APIキー")
                    Spacer()
                    Text(viewModel.apiKeyDisplayStatus)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        viewModel.showingAPIKeyField.toggle()
                        if !viewModel.showingAPIKeyField {
                            viewModel.apiKeyTestResult = ""
                        }
                    }) {
                        Text(viewModel.showingAPIKeyField ? "キャンセル" : "設定")
                    }
                    .buttonStyle(.bordered)
                }
                
                if viewModel.showingAPIKeyField {
                    VStack(alignment: .leading, spacing: 8) {
                        SecureField("sk-ant-api-03-...", text: $viewModel.claudeAPIKey)
                            .textFieldStyle(.roundedBorder)
                        
                        if !viewModel.apiKeyTestResult.isEmpty {
                            Text(viewModel.apiKeyTestResult)
                                .font(.caption)
                                .foregroundColor(
                                    viewModel.apiKeyTestResult.contains("✅") ? .green :
                                    viewModel.apiKeyTestResult.contains("❌") ? .red : .orange
                                )
                        }
                        
                        HStack {
                            Button("テスト") {
                                Task {
                                    await viewModel.testAPIKey()
                                }
                            }
                            .buttonStyle(.bordered)
                            .disabled(viewModel.isTestingAPIKey || viewModel.claudeAPIKey.isEmpty)
                            
                            Button("保存") {
                                viewModel.saveAPIKey()
                                viewModel.showingAPIKeyField = false
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.claudeAPIKey.isEmpty)
                            
                            if !viewModel.claudeAPIKey.isEmpty {
                                Button("削除") {
                                    viewModel.clearAPIKey()
                                }
                                .buttonStyle(.bordered)
                                .foregroundColor(.red)
                            }
                            
                            Spacer()
                            
                            if viewModel.isTestingAPIKey {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                }
            }
        }
    }
}