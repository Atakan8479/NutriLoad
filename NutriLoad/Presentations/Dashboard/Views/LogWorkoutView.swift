import SwiftUI

struct LogWorkoutView: View {
    @ObservedObject var coordinator: AppCoordinator
    @StateObject private var viewModel = LogWorkoutViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Set Detayları").font(.custom("Times New Roman", size: 14))) {
                    TextField("Ağırlık (kg)", text: $viewModel.weight)
                        .keyboardType(.decimalPad)
                    
                    TextField("Tekrar Sayısı", text: $viewModel.reps)
                        .keyboardType(.numberPad)
                    
                    HStack {
                        Text("Zorluk (RPE): \(viewModel.rpe)")
                        Spacer()
                        Slider(value: Binding(
                            get: { Double(viewModel.rpe) ?? 8.0 },
                            set: { viewModel.rpe = String(format: "%.1f", $0) }
                        ), in: 1...10, step: 0.5)
                    }
                }
                
                Button(action: {
                    Task {
                        await viewModel.saveWorkout {
                            // Başarılı kayıttan sonra ana sayfaya geri dön
                            coordinator.navigate(to: .dashboard)
                        }
                    }
                }) {
                    HStack {
                        Spacer()
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("Antrenmanı Kaydet ve Senkronize Et")
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.weight.isEmpty || viewModel.reps.isEmpty || viewModel.isSaving)
                .listRowBackground(Color(red: 0.2, green: 0.35, blue: 0.55))
                .foregroundColor(.white)
            }
            .navigationTitle("Yeni Antrenman")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        coordinator.navigate(to: .dashboard)
                    }
                }
            }
        }
    }
}
