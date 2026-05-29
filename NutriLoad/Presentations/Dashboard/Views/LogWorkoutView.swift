import SwiftUI

struct LogWorkoutView: View {
    @ObservedObject var coordinator: AppCoordinator
    @StateObject private var viewModel = LogWorkoutViewModel()
    
    // Sensör yöneticisini doğrudan arayüze bağlıyoruz
    @StateObject private var telemetry = SensorTelemetryManager.shared
    
    var body: some View {
        NavigationView {
            Form {
                // 1. Telemetry & Tracking Section
                Section(header: Text("Live Telemetry").font(.custom("Times New Roman", size: 14))) {
                    VStack(spacing: 16) {
                        HStack {
                            Text("Form Stability")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Spacer()
                            Text(String(format: "%.1f / 100", telemetry.stabilityScore))
                                .font(.headline)
                                .foregroundColor(telemetry.stabilityScore > 80 ? .green : .orange)
                        }
                        
                        // Progress bar for visual stability feedback
                        ProgressView(value: telemetry.stabilityScore, total: 100)
                            .progressViewStyle(LinearProgressViewStyle(tint: telemetry.stabilityScore > 80 ? .green : .orange))
                        
                        if telemetry.hasAnomaly {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.red)
                                Text("Form breakdown detected!")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            // Küçük bir zıplama animasyonu ile dikkati çek
                            .transition(.scale)
                            .animation(.spring(), value: telemetry.hasAnomaly)
                        }
                        
                        Button(action: {
                            if telemetry.isTracking {
                                telemetry.stopTracking()
                            } else {
                                telemetry.startTracking()
                            }
                        }) {
                            Text(telemetry.isTracking ? "Stop Tracking" : "Start Set Tracking")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(telemetry.isTracking ? Color.red.opacity(0.1) : Color(red: 0.2, green: 0.35, blue: 0.55).opacity(0.1))
                                .foregroundColor(telemetry.isTracking ? .red : Color(red: 0.2, green: 0.35, blue: 0.55))
                                .cornerRadius(8)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // 2. Set Details Section
                Section(header: Text("Set Details").font(.custom("Times New Roman", size: 14))) {
                    TextField("Weight (kg)", text: $viewModel.weight)
                        .keyboardType(.decimalPad)
                    
                    TextField("Reps", text: $viewModel.reps)
                        .keyboardType(.numberPad)
                    
                    HStack {
                        Text("RPE: \(viewModel.rpe)")
                        Spacer()
                        Slider(value: Binding(
                            get: { Double(viewModel.rpe) ?? 8.0 },
                            set: { viewModel.rpe = String(format: "%.1f", $0) }
                        ), in: 1...10, step: 0.5)
                    }
                }
                
                // 3. Save Button
                Button(action: {
                    // Kaydederken sensörü de güvenli bir şekilde kapatıyoruz
                    if telemetry.isTracking {
                        telemetry.stopTracking()
                    }
                    
                    Task {
                        await viewModel.saveWorkout {
                            coordinator.navigate(to: .dashboard)
                        }
                    }
                }) {
                    HStack {
                        Spacer()
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("Save & Sync Workout")
                                .fontWeight(.bold)
                        }
                        Spacer()
                    }
                }
                .disabled(viewModel.weight.isEmpty || viewModel.reps.isEmpty || viewModel.isSaving)
                .listRowBackground(Color(red: 0.2, green: 0.35, blue: 0.55))
                .foregroundColor(.white)
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if telemetry.isTracking { telemetry.stopTracking() }
                        coordinator.navigate(to: .dashboard)
                    }
                }
            }
            .onDisappear {
                // Sayfa beklenmedik şekilde kapanırsa sensörü kapat (Memory Leak önlemi)
                if telemetry.isTracking {
                    telemetry.stopTracking()
                }
            }
        }
    }
}
