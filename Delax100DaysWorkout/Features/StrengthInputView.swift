import SwiftUI

struct StrengthInputView: View {
    @Binding var strengthDetails: [StrengthDetail]
    @State private var selectedExercise = StrengthExercise.benchPress
    @State private var customExercise = ""
    @State private var sets = 3
    @State private var reps = 10
    @State private var weight = 0.0
    @State private var notes = ""
    
    var body: some View {
        Section(header: Text("筋トレ詳細")) {
            ForEach(strengthDetails) { detail in
                VStack(alignment: .leading) {
                    Text(detail.exercise)
                        .font(.headline)
                    Text("\(detail.sets)セット × \(detail.reps)レップ @ \(detail.weight, specifier: "%.1f")kg")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .onDelete { indexSet in
                strengthDetails.remove(atOffsets: indexSet)
            }
        }
        
        Section(header: Text("エクササイズを追加")) {
            Picker("種目", selection: $selectedExercise) {
                ForEach(StrengthExercise.allCases, id: \.self) { exercise in
                    Text(exercise.rawValue).tag(exercise)
                }
            }
            
            if selectedExercise == .other {
                TextField("カスタム種目名", text: $customExercise)
            }
            
            HStack {
                Text("セット数")
                Spacer()
                Stepper("\(sets)", value: $sets, in: 1...10)
            }
            
            HStack {
                Text("レップ数")
                Spacer()
                Stepper("\(reps)", value: $reps, in: 1...50)
            }
            
            HStack {
                Text("重量 (kg)")
                Spacer()
                TextField("0", value: $weight, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            
            TextField("メモ", text: $notes)
            
            Button("エクササイズを追加") {
                let exerciseName = selectedExercise == .other ? customExercise : selectedExercise.rawValue
                let detail = StrengthDetail(
                    exercise: exerciseName,
                    sets: sets,
                    reps: reps,
                    weight: weight,
                    notes: notes.isEmpty ? nil : notes
                )
                strengthDetails.append(detail)
                
                customExercise = ""
                notes = ""
            }
            .disabled(selectedExercise == .other && customExercise.isEmpty)
        }
    }
}