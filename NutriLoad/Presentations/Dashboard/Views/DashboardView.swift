import SwiftUI

struct DashboardView: View {
    @ObservedObject var coordinator: AppCoordinator
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("NutriLoad Analitik")
                        .font(.custom("Times New Roman", size: 32))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    // Dinamik Hedef Kartı
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Günün Hedef Proteini")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            // ViewModel'den gelen hesaplanmış aralık
                            Text("\(viewModel.dailyProteinTarget.lowerBound, specifier: "%.1f")g - \(viewModel.dailyProteinTarget.upperBound, specifier: "%.1f")g")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Swift Charts Komponentimiz
                    if !viewModel.recentWorkouts.isEmpty {
                        TonnageChartView(workouts: viewModel.recentWorkouts)
                            .padding(.horizontal)
                    } else if !viewModel.isLoading {
                        Text("Henüz veri bulunmuyor.")
                            .foregroundColor(.gray)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        coordinator.navigate(to: .logWorkout)
                    }) {
                        Text("Yeni Antrenman Ekle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(red: 0.2, green: 0.35, blue: 0.55))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            // Sayfa yüklendiğinde asenkron veriyi çek
            .task {
                await viewModel.loadDashboardData()
            }
        }
    }
}
