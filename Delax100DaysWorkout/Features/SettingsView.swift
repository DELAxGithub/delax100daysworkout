import SwiftUI

struct SettingsView: View {
    @State var viewModel: SettingsViewModel
    @State private var showingCredentialSettings = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Challenge Period")) {
                    DatePicker("Goal Date", selection: $viewModel.goalDate, displayedComponents: .date)
                }
                
                Section(header: Text("セキュリティ設定")) {
                    Button(action: {
                        showingCredentialSettings = true
                    }) {
                        HStack {
                            Image(systemName: "lock.shield")
                                .foregroundColor(.blue)
                            Text("認証情報の管理")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                    .foregroundColor(.primary)
                }

                Section(header: Text("Weight Goals (kg)")) {
                    HStack {
                        Text("Start Weight")
                        Spacer()
                        TextField("Weight", value: $viewModel.startWeightKg, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Goal Weight")
                        Spacer()
                        TextField("Weight", value: $viewModel.goalWeightKg, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section(header: Text("Cycling FTP Goals (Watts)")) {
                    HStack {
                        Text("Start FTP")
                        Spacer()
                        TextField("FTP", value: $viewModel.startFtp, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Goal FTP")
                        Spacer()
                        TextField("FTP", value: $viewModel.goalFtp, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("Claude API設定")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("APIキー")
                            Spacer()
                            Text(viewModel.apiKeyDisplayStatus)
                                .foregroundColor(.secondary)
                            
                            Button(viewModel.showingAPIKeyField ? "キャンセル" : "設定") {
                                viewModel.showingAPIKeyField.toggle()
                                if !viewModel.showingAPIKeyField {
                                    viewModel.apiKeyTestResult = ""
                                }
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
                
                Section(header: Text("AI分析設定")) {
                    Toggle("AI分析を有効にする", isOn: $viewModel.aiAnalysisEnabled)
                        .onChange(of: viewModel.aiAnalysisEnabled) { _, _ in
                            viewModel.updateAISettings()
                        }
                    
                    if viewModel.aiAnalysisEnabled {
                        HStack {
                            Text("更新頻度（日）")
                            Spacer()
                            TextField("日数", value: $viewModel.updateFrequencyDays, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                                .onChange(of: viewModel.updateFrequencyDays) { _, _ in
                                    viewModel.updateAISettings()
                                }
                        }
                        
                        if let lastDate = viewModel.lastAnalysisDate {
                            HStack {
                                Text("最終分析日時")
                                Spacer()
                                Text(lastDate.formatted(date: .abbreviated, time: .shortened))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section(header: Text("分析情報")) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("分析対象")
                            Spacer()
                            Text(viewModel.analysisDataDescription)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("最新の結果")
                            Spacer()
                            Text(viewModel.analysisResultDescription)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("使用状況")
                            Spacer()
                            Text(viewModel.monthlyUsageDescription)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("累計分析回数")
                            Spacer()
                            Text("\(viewModel.analysisCount)回")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("AI分析実行")) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("手動分析実行")
                                    .font(.headline)
                                Text("あなたの進捗データを基に、最適なトレーニング調整を提案します")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        
                        HStack {
                            Text("状態: \(viewModel.analysisStatusText)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button(action: {
                                Task {
                                    await viewModel.runManualAnalysis()
                                }
                            }) {
                                HStack {
                                    if viewModel.isAnalyzing {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                    Text(viewModel.isAnalyzing ? "分析中..." : "今すぐ分析")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!viewModel.canRunAnalysis)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: viewModel.save)
                }
            }
            .alert("Saved", isPresented: $viewModel.showSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your goals have been updated successfully.")
            }
            .sheet(isPresented: $showingCredentialSettings) {
                CredentialSettingsView()
            }
        }
    }
}