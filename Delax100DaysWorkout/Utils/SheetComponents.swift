import SwiftUI
import UIKit

// MARK: - Save State Management

@MainActor
class SaveStateManager: ObservableObject {
    @Published var isSaving = false
    @Published var showingSaveSuccess = false
    @Published var showingError = false
    @Published var errorMessage = ""
    
    func startSaving() {
        isSaving = true
    }
    
    func saveSuccess() {
        isSaving = false
        showingSaveSuccess = true
        
        // ハプティックフィードバック
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.prepare()
        impactFeedback.impactOccurred()
    }
    
    func saveError(_ message: String) {
        isSaving = false
        errorMessage = message
        showingError = true
    }
    
    func reset() {
        isSaving = false
        showingSaveSuccess = false
        showingError = false
        errorMessage = ""
    }
}

// MARK: - Sheet Toolbar

struct SheetToolbar: View {
    let title: String
    let saveAction: () -> Void
    let isSaveDisabled: Bool
    let isSaving: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack {
            // キャンセルボタンは親がEnvironment dismissで管理
            Spacer()
            
            Text(title)
                .font(.headline)
            
            Spacer()
            
            Button(action: saveAction) {
                HStack(spacing: 6) {
                    if isSaving {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    }
                    Text(isSaving ? "保存中..." : "保存")
                }
                .animation(.easeInOut(duration: 0.2), value: isSaving)
            }
            .disabled(isSaveDisabled || isSaving)
        }
        .padding()
    }
}

// MARK: - Saveable Sheet Wrapper

struct SaveableSheet<Content: View>: View {
    let title: String
    let content: Content
    let saveAction: () -> Void
    let isSaveDisabled: Bool
    
    @StateObject private var saveStateManager = SaveStateManager()
    @Environment(\.dismiss) private var dismiss
    
    init(
        title: String,
        isSaveDisabled: Bool = false,
        saveAction: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.isSaveDisabled = isSaveDisabled
        self.saveAction = saveAction
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            SheetToolbar(
                title: title,
                saveAction: handleSave,
                isSaveDisabled: isSaveDisabled,
                isSaving: saveStateManager.isSaving
            )
            
            Divider()
            
            content
        }
        .alert("保存しました！", isPresented: $saveStateManager.showingSaveSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("データが正常に保存されました。")
        }
        .alert("保存エラー", isPresented: $saveStateManager.showingError) {
            Button("OK") { }
        } message: {
            Text(saveStateManager.errorMessage)
        }
    }
    
    private func handleSave() {
        saveStateManager.startSaving()
        
        Task {
            do {
                saveAction()
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒待機
                await MainActor.run {
                    saveStateManager.saveSuccess()
                }
            } catch {
                await MainActor.run {
                    saveStateManager.saveError(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Standard Sheet Modifier

extension View {
    func standardSheet<Content: View>(
        isPresented: Binding<Bool>,
        title: String,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            NavigationStack {
                content()
                    .navigationTitle(title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("キャンセル") {
                                isPresented.wrappedValue = false
                            }
                        }
                    }
            }
        }
    }
    
    func saveableSheet<Content: View>(
        isPresented: Binding<Bool>,
        title: String,
        isSaveDisabled: Bool = false,
        saveAction: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.sheet(isPresented: isPresented) {
            NavigationStack {
                SaveableSheet(
                    title: title,
                    isSaveDisabled: isSaveDisabled,
                    saveAction: saveAction
                ) {
                    content()
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("キャンセル") {
                            isPresented.wrappedValue = false
                        }
                    }
                }
            }
        }
    }
}