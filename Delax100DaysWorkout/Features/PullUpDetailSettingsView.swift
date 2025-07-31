import SwiftUI

struct PullUpDetailSettingsView: View {
    @Bindable var strengthDetail: StrengthDetail
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedVariant: PullUpVariant
    @State private var isAssisted: Bool
    @State private var assistWeight: Double
    @State private var maxConsecutiveReps: Int
    
    init(strengthDetail: StrengthDetail) {
        self.strengthDetail = strengthDetail
        _selectedVariant = State(initialValue: strengthDetail.pullUpVariant ?? .normal)
        _isAssisted = State(initialValue: strengthDetail.isAssisted)
        _assistWeight = State(initialValue: strengthDetail.assistWeight)
        _maxConsecutiveReps = State(initialValue: strengthDetail.maxConsecutiveReps)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("グリップバリエーション") {
                    Picker("グリップ", selection: $selectedVariant) {
                        ForEach(PullUpVariant.allCases, id: \.self) { variant in
                            VStack(alignment: .leading) {
                                Text(variant.rawValue)
                                    .font(.headline)
                                Text(variant.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .tag(variant)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    // ターゲット筋群表示
                    VStack(alignment: .leading, spacing: 8) {
                        Text("主要ターゲット筋群")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                            ForEach(selectedVariant.targetMuscles, id: \.self) { muscle in
                                Text(muscle)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.orange.opacity(0.1))
                                    .foregroundColor(.orange)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("アシスト設定") {
                    Toggle("アシストマシン使用", isOn: $isAssisted)
                    
                    if isAssisted {
                        HStack {
                            Text("アシスト重量")
                            Spacer()
                            TextField("0.0", value: $assistWeight, format: .number.precision(.fractionLength(1)))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("kg")
                                .foregroundColor(.secondary)
                        }
                        
                        Text("アシスト重量は補助される重量です。軽いほど難易度が高くなります。")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("パフォーマンス記録") {
                    HStack {
                        Text("連続最大回数")
                        Spacer()
                        TextField("0", value: $maxConsecutiveReps, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("回")
                            .foregroundColor(.secondary)
                    }
                    
                    if maxConsecutiveReps > 0 {
                        HStack {
                            Image(systemName: "trophy.fill")
                                .foregroundColor(.orange)
                            Text("素晴らしい！連続\(maxConsecutiveReps)回は立派な記録です！")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("基本設定") {
                    HStack {
                        Text("セット数")
                        Spacer()
                        Stepper("\(strengthDetail.sets)", value: Binding(
                            get: { strengthDetail.sets },
                            set: { strengthDetail.sets = $0 }
                        ), in: 1...10)
                    }
                    
                    HStack {
                        Text("各セットのレップ数")
                        Spacer()
                        Stepper("\(strengthDetail.reps)", value: Binding(
                            get: { strengthDetail.reps },
                            set: { strengthDetail.reps = $0 }
                        ), in: 1...30)
                    }
                    
                    TextField("メモ", text: Binding(
                        get: { strengthDetail.notes ?? "" },
                        set: { strengthDetail.notes = $0.isEmpty ? nil : $0 }
                    ), axis: .vertical)
                    .lineLimit(3...6)
                }
            }
            .navigationTitle("プルアップ詳細")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        saveChanges()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func saveChanges() {
        strengthDetail.pullUpVariantRawValue = selectedVariant.rawValue
        strengthDetail.isAssisted = isAssisted
        strengthDetail.assistWeight = assistWeight
        strengthDetail.maxConsecutiveReps = maxConsecutiveReps
        
        // プルアップは自重なので重量は0
        strengthDetail.weight = 0.0
    }
}

#Preview {
    let sampleDetail = StrengthDetail(
        pullUpVariant: .normal,
        sets: 3,
        reps: 8,
        isAssisted: false,
        assistWeight: 0.0,
        maxConsecutiveReps: 12,
        notes: "フォーム意識して丁寧に"
    )
    
    return PullUpDetailSettingsView(strengthDetail: sampleDetail)
}