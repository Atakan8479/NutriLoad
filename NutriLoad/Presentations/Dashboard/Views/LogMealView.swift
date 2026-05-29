import SwiftUI

struct LogMealView: View {
    @ObservedObject var coordinator: AppCoordinator
    @StateObject private var viewModel = LogMealViewModel()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Meal Details").font(.custom("Times New Roman", size: 14))) {
                    TextField("Meal Name (e.g., Oatmeal & Eggs)", text: $viewModel.mealName)
                    
                    TextField("Protein Amount (g)", text: $viewModel.proteinAmount)
                        .keyboardType(.decimalPad)
                }
                
                Button(action: {
                    Task {
                        await viewModel.saveMeal {
                            coordinator.navigate(to: .dashboard)
                        }
                    }
                }) {
                    HStack {
                        Spacer()
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("Save & Sync Meal")
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.mealName.isEmpty || viewModel.proteinAmount.isEmpty || viewModel.isSaving)
                .listRowBackground(Color(red: 0.2, green: 0.35, blue: 0.55))
                .foregroundColor(.white)
            }
            .navigationTitle("Log Nutrition")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        coordinator.navigate(to: .dashboard)
                    }
                }
            }
        }
    }
}
