import SwiftUI

struct SettingsView: View {
    @State var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Challenge Period")) {
                    DatePicker("Goal Date", selection: $viewModel.goalDate, displayedComponents: .date)
                }

                Section(header: Text("Weight Goals (kg)")) {
                    HStack {
                        Text("Start Weight")
                        Spacer()
                        TextField("Weight", value: $viewModel.startWeightKg, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Goal Weight")
                        Spacer()
                        TextField("Weight", value: $viewModel.goalWeightKg, format: .number.precision(.fractionLength(1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section(header: Text("Cycling FTP Goals (Watts)")) {
                    HStack {
                        Text("Start FTP")
                        Spacer()
                        TextField("FTP", value: $viewModel.startFtp, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Goal FTP")
                        Spacer()
                        TextField("FTP", value: $viewModel.goalFtp, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save", action: viewModel.save)
                }
            }
            .alert("Saved", isPresented: $viewModel.showSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your goals have been updated successfully.")
            }
        }
    }
}