import SwiftUI

struct AIAnalysisSection: View {
    @Binding var viewModel: SettingsViewModel
    
    var body: some View {
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
    }
}