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
    @State private var showImagePicker = false
    
    let currentView: String
    let preCapuredScreenshot: Data?
    
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
                        VStack(spacing: 12) {
                            Text("スクリーンショットが取得できませんでした")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Button {
                                showImagePicker = true
                            } label: {
                                Label("写真から選択", systemImage: "photo")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    if screenshotData != nil {
                        Button {
                            showImagePicker = true
                        } label: {
                            Label("別の写真を選択", systemImage: "photo.badge.plus")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
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
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(imageData: $screenshotData)
        }
        .onAppear {
            // 事前取得されたスクリーンショットを使用
            screenshotData = preCapuredScreenshot
        }
    }
    
    private func submitReport() {
        isSubmitting = true
        
        Task {
            do {
                // 現在のスクリーンショットデータを使用してBugReportを作成
                let report = bugReportManager.createBugReport(
                    category: category,
                    description: description,
                    reproductionSteps: reproductionSteps.isEmpty ? nil : reproductionSteps,
                    expectedBehavior: expectedBehavior.isEmpty ? nil : expectedBehavior,
                    actualBehavior: actualBehavior.isEmpty ? nil : actualBehavior,
                    currentView: currentView,
                    screenshot: screenshotData
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

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.imageData = image.jpegData(compressionQuality: 0.8)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    BugReportView(currentView: "Preview", preCapuredScreenshot: nil)
}