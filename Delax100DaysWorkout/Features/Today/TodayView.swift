import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: TodayViewModel?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if let viewModel = viewModel {
                    VStack(spacing: 20) {
                        // Progress section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("今日のタスク")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("進捗: \(Int(viewModel.progressPercentage * 100))%")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                        
                        // Task list
                        if viewModel.todaysTasks.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 60))
                                    .foregroundColor(.green)
                                
                                Text("今日のタスクはありません")
                                    .font(.headline)
                            }
                            .padding(40)
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                        } else {
                            ForEach(viewModel.todaysTasks) { task in
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(task.title)
                                        .font(.headline)
                                    
                                    if let description = task.taskDescription {
                                        Text(description)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(UIColor.secondarySystemBackground))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding()
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(100)
                }
            }
            .navigationTitle("今日のタスク")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            if viewModel == nil {
                viewModel = TodayViewModel(modelContext: modelContext)
            }
        }
    }
}