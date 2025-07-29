import SwiftUI

struct CyclingInputView: View {
    @Binding var distance: Double
    @Binding var duration: Int
    @Binding var averagePower: Double
    @Binding var intensity: CyclingIntensity
    @Binding var notes: String
    
    var body: some View {
        Section(header: Text("サイクリング詳細")) {
            HStack {
                Text("距離 (km)")
                Spacer()
                TextField("0", value: $distance, format: .number.precision(.fractionLength(1)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Text("時間 (分)")
                Spacer()
                TextField("0", value: $duration, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Text("平均パワー (W)")
                Spacer()
                TextField("0", value: $averagePower, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
            }
            
            Picker("強度", selection: $intensity) {
                ForEach(CyclingIntensity.allCases, id: \.self) { intensity in
                    Text(intensity.description).tag(intensity)
                }
            }
            
            TextField("メモ", text: $notes, axis: .vertical)
                .lineLimit(2...4)
        }
    }
}