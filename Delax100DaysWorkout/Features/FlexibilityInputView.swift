import SwiftUI

struct FlexibilityInputView: View {
    @Binding var forwardBendDistance: Double
    @Binding var leftSplitAngle: Double
    @Binding var rightSplitAngle: Double
    @Binding var duration: Int
    @Binding var notes: String
    
    var body: some View {
        Section(header: Text("柔軟性詳細")) {
            VStack(alignment: .leading) {
                Text("前屈距離 (cm)")
                Slider(value: $forwardBendDistance, in: -30...30, step: 1) {
                    Text("前屈")
                } minimumValueLabel: {
                    Text("-30")
                } maximumValueLabel: {
                    Text("30")
                }
                Text("\(forwardBendDistance, specifier: "%.0f") cm")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading) {
                Text("左開脚角度 (度)")
                Slider(value: $leftSplitAngle, in: 0...180, step: 5) {
                    Text("左開脚")
                } minimumValueLabel: {
                    Text("0°")
                } maximumValueLabel: {
                    Text("180°")
                }
                Text("\(leftSplitAngle, specifier: "%.0f")度")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading) {
                Text("右開脚角度 (度)")
                Slider(value: $rightSplitAngle, in: 0...180, step: 5) {
                    Text("右開脚")
                } minimumValueLabel: {
                    Text("0°")
                } maximumValueLabel: {
                    Text("180°")
                }
                Text("\(rightSplitAngle, specifier: "%.0f")度")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack {
                Text("実施時間 (分)")
                Spacer()
                TextField("0", value: $duration, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
            }
            
            TextField("メモ", text: $notes, axis: .vertical)
                .lineLimit(2...4)
        }
    }
}