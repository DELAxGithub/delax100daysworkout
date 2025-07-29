import SwiftUI

struct BugReportView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var bugReportManager = BugReportManager.shared
    
    @State private var category: BugCategory = .other
    @State private var description = ""
    @State private var reproductionSteps = ""
    @State private var expectedBehavior = ""
    @State private var actualBehavior = ""
    @State private var screenshotData: Data?
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    let currentView: String
    
    var body: some View {
        NavigationView {
            Form {
                Section("何が起きましたか？") {
                    Picker("カテゴリ", selection: $category) {
                        ForEach(BugCategory.allCases, id: \.self) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                    
                    TextField("問題を簡単に説明してください", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("詳細情報（任意）") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("再現手順")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $reproductionSteps)
                            .frame(minHeight: 60)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("期待される動作")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $expectedBehavior)
                            .frame(minHeight: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("実際の動作")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $actualBehavior)
                            .frame(minHeight: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                }
                
                Section("スクリーンショット") {
                    if let screenshotData = screenshotData,
                       let uiImage = UIImage(data: screenshotData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    } else {
                        Text("スクリーンショットは自動で取得されました")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Text("デバイス情報とログは自動的に含まれます")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("バグを報告")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("送信") {
                        submitReport()
                    }
                    .disabled(isSubmitting || description.isEmpty)
                }
            }
            .disabled(isSubmitting)
            .overlay {
                if isSubmitting {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView("送信中...")
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        }
                }
            }
            .alert("送信完了", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("バグ報告を受け付けました。ご協力ありがとうございます。")
            }
            .alert("エラー", isPresented: $showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            captureInitialScreenshot()
        }
    }
    
    private func captureInitialScreenshot() {
        // BugReportManagerが既にスクリーンショットを持っている場合
        // ここでは表示のためにダミーデータを設定
        screenshotData = bugReportManager.captureBugReport(
            category: .other,
            currentView: currentView
        ).screenshot
    }
    
    private func submitReport() {
        isSubmitting = true
        
        Task {
            do {
                let report = bugReportManager.captureBugReport(
                    category: category,
                    description: description,
                    reproductionSteps: reproductionSteps.isEmpty ? nil : reproductionSteps,
                    expectedBehavior: expectedBehavior.isEmpty ? nil : expectedBehavior,
                    actualBehavior: actualBehavior.isEmpty ? nil : actualBehavior,
                    currentView: currentView
                )
                
                try await bugReportManager.submitBugReport(report)
                
                await MainActor.run {
                    isSubmitting = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "送信に失敗しました: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    BugReportView(currentView: "Preview")
}