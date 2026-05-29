import SwiftUI

struct DashboardView: View {
    @ObservedObject var coordinator: AppCoordinator
    @StateObject private var viewModel = DashboardViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Header Section
                    Text("NutriLoad Analytics")
                        .font(.custom("Times New Roman", size: 32))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    // Dynamic Protein Target Card
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Daily Protein Target")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text(String(format: "%.1f g - %.1f g", viewModel.dailyProteinTarget.lowerBound, viewModel.dailyProteinTarget.upperBound))
                                    .font(.title2)
                                    .fontWeight(.bold)
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // AI Recommendation Card
                    HStack {
                        VStack(alignment: .leading) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.yellow)
                                Text("AI Tonnage Recommendation")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            
                            if viewModel.isLoading {
                                ProgressView()
                            } else {
                                Text("\(viewModel.aiRecommendedTonnage, specifier: "%.0f") kg")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color(red: 0.2, green: 0.35, blue: 0.55))
                            }
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.yellow.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Chart Section
                    if !viewModel.recentWorkouts.isEmpty {
                        TonnageChartView(workouts: viewModel.recentWorkouts)
                            .padding(.horizontal)
                    } else if !viewModel.isLoading {
                        VStack(spacing: 12) {
                            Image(systemName: "chart.bar.xaxis")
                                .font(.system(size: 40))
                                .foregroundColor(.gray.opacity(0.5))
                            Text("No workout data available.")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 40)
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            coordinator.navigate(to: .logWorkout)
                        }) {
                            Text("Log Workout")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 0.2, green: 0.35, blue: 0.55))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            coordinator.navigate(to: .logMeal)
                        }) {
                            Text("Log Meal")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .foregroundColor(Color(red: 0.2, green: 0.35, blue: 0.55))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadDashboardData()
            }
        }
    }
}
