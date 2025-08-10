import SwiftUI

// MARK: - 機能テスト用UIコンポーネント

struct FunctionalTestCard: View {
    let onRunTests: () -> Void
    let testResults: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "testtube.2")
                    .foregroundColor(.blue)
                Text("機能テスト")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("実行", action: onRunTests)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
            
            Text("WPR計算精度とボトルネック検出システムの動作確認")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if !testResults.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("最新結果:")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 2) {
                            ForEach(testResults.suffix(5), id: \.self) { result in
                                Text(result)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxHeight: 80)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct FunctionalTestResultsView: View {
    let results: [String]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(results, id: \.self) { result in
                        HStack(alignment: .top) {
                            if result.contains("✅") {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            } else if result.contains("❌") {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            } else if result.contains("🧪") || result.contains("📊") || 
                                     result.contains("🔍") || result.contains("🔄") || 
                                     result.contains("🧬") {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                            
                            Text(result)
                                .font(.system(.caption, design: .monospaced))
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("テスト結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - テスト結果サマリーカード

struct TestResultsSummaryCard: View {
    let testResults: [String]
    
    private var passedTests: Int {
        testResults.filter { $0.contains("✅") }.count
    }
    
    private var failedTests: Int {
        testResults.filter { $0.contains("❌") }.count
    }
    
    private var totalTests: Int {
        passedTests + failedTests
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("テスト結果サマリー")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            if totalTests > 0 {
                HStack(spacing: 20) {
                    VStack {
                        Text("\(passedTests)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("成功")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(failedTests)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        Text("失敗")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack {
                        Text("\(String(format: "%.0f", Double(passedTests) / Double(totalTests) * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("成功率")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                
                // プログレスバー
                ProgressView(value: Double(passedTests), total: Double(totalTests))
                    .progressViewStyle(LinearProgressViewStyle(tint: passedTests == totalTests ? .green : .blue))
            } else {
                Text("テストを実行してください")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// MARK: - テスト実行状態表示

struct TestExecutionStatusView: View {
    let isRunning: Bool
    let currentTest: String?
    
    var body: some View {
        HStack {
            if isRunning {
                ProgressView()
                    .scaleEffect(0.8)
                
                VStack(alignment: .leading) {
                    Text("テスト実行中...")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    if let currentTest = currentTest {
                        Text(currentTest)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("テスト完了")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    VStack(spacing: 20) {
        FunctionalTestCard(
            onRunTests: {},
            testResults: [
                "🧪 WPR機能テスト開始...",
                "✅ ベースラインWPR: 3.57 正確",
                "✅ 現在WPR: 3.97 正確",
                "✅ 目標達成率: 42.9%",
                "✅ WPR機能テスト完了"
            ]
        )
        
        TestResultsSummaryCard(testResults: [
            "✅ Test 1",
            "✅ Test 2", 
            "❌ Test 3",
            "✅ Test 4"
        ])
        
        TestExecutionStatusView(
            isRunning: true,
            currentTest: "WPR計算精度テスト"
        )
    }
    .padding()
}