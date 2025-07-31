import SwiftUI

struct PullUpInputView: View {
    @Binding var strengthDetail: StrengthDetail
    @State private var selectedVariant: PullUpVariant = .normal
    @State private var sets: Int = 3
    @State private var reps: Int = 8
    @State private var isAssisted: Bool = false
    @State private var assistWeight: Double = 0.0
    @State private var maxConsecutiveReps: Int = 0
    @State private var notes: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // ヘッダー
            HStack {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("プルアップ記録")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // バリエーション選択
            VStack(alignment: .leading, spacing: 12) {
                Text("グリップ")
                    .font(.headline)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                    ForEach(PullUpVariant.allCases, id: \.self) { variant in
                        VariantCard(
                            variant: variant,
                            isSelected: selectedVariant == variant
                        ) {
                            selectedVariant = variant
                        }
                    }
                }
            }
            
            // セット・レップ設定
            VStack(alignment: .leading, spacing: 12) {
                Text("セット・レップ")
                    .font(.headline)
                
                HStack(spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("セット数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Stepper("\(sets)", value: $sets, in: 1...10)
                            .labelsHidden()
                    }
                    
                    VStack(alignment: .leading) {
                        Text("各セットのレップ数")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Stepper("\(reps)", value: $reps, in: 1...30)
                            .labelsHidden()
                    }
                }
            }
            
            // アシスト設定
            VStack(alignment: .leading, spacing: 12) {
                Toggle("アシスト使用", isOn: $isAssisted)
                    .font(.headline)
                
                if isAssisted {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("アシスト重量 (kg)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("0.0", value: $assistWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            
                            Text("kg")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.leading)
                }
            }
            
            // 連続最大回数
            VStack(alignment: .leading, spacing: 12) {
                Text("連続最大回数（オプション）")
                    .font(.headline)
                
                HStack {
                    TextField("0", value: $maxConsecutiveReps, format: .number)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                    
                    Text("回")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if maxConsecutiveReps > 0 {
                        Text("🎯 記録更新!")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            
            // メモ
            VStack(alignment: .leading, spacing: 8) {
                Text("メモ")
                    .font(.headline)
                
                TextField("フォームの感想、次回への課題など", text: $notes, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            }
            
            // ターゲット筋肉表示
            VStack(alignment: .leading, spacing: 8) {
                Text("主要ターゲット筋群")
                    .font(.headline)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(selectedVariant.targetMuscles, id: \.self) { muscle in
                            Text(muscle)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.1))
                                .foregroundColor(.orange)
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .onChange(of: selectedVariant) { updateStrengthDetail() }
        .onChange(of: sets) { updateStrengthDetail() }
        .onChange(of: reps) { updateStrengthDetail() }
        .onChange(of: isAssisted) { updateStrengthDetail() }
        .onChange(of: assistWeight) { updateStrengthDetail() }
        .onChange(of: maxConsecutiveReps) { updateStrengthDetail() }
        .onChange(of: notes) { updateStrengthDetail() }
        .onAppear {
            loadFromStrengthDetail()
        }
    }
    
    private func updateStrengthDetail() {
        strengthDetail = StrengthDetail(
            pullUpVariant: selectedVariant,
            sets: sets,
            reps: reps,
            isAssisted: isAssisted,
            assistWeight: assistWeight,
            maxConsecutiveReps: maxConsecutiveReps,
            notes: notes.isEmpty ? nil : notes
        )
    }
    
    private func loadFromStrengthDetail() {
        if let variant = strengthDetail.pullUpVariant {
            selectedVariant = variant
        }
        sets = strengthDetail.sets
        reps = strengthDetail.reps
        isAssisted = strengthDetail.isAssisted
        assistWeight = strengthDetail.assistWeight
        maxConsecutiveReps = strengthDetail.maxConsecutiveReps
        notes = strengthDetail.notes ?? ""
    }
}

struct VariantCard: View {
    let variant: PullUpVariant
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(variant.rawValue)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.orange)
                    }
                }
                
                Text(variant.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(12)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.orange.opacity(0.1) : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    @Previewable @State var strengthDetail = StrengthDetail(exercise: "プルアップ", sets: 3, reps: 8, weight: 0.0)
    
    return NavigationStack {
        PullUpInputView(strengthDetail: $strengthDetail)
            .navigationTitle("プルアップ")
    }
}