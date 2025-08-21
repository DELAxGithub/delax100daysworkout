import SwiftUI

struct AnalysisInfoSection: View {
    @Binding var viewModel: SettingsViewModel
    
    var body: some View {
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
    }
}