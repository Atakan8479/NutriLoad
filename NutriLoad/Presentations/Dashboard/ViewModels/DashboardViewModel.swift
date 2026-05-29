import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    
    @Published var recentWorkouts: [WorkoutEntity] = []
    @Published var dailyProteinTarget: ClosedRange<Double> = 150.0...150.0
    @Published var aiRecommendedTonnage: Double = 0.0
    @Published var isLoading: Bool = false
    
    private let workoutRepository: WorkoutRepositoryProtocol
    private let optimizationEngine = MacroOptimizationEngine.shared
    
    init(workoutRepository: WorkoutRepositoryProtocol = CoreDataWorkoutRepository()) {
        self.workoutRepository = workoutRepository
    }
    
    func loadDashboardData() async {
        isLoading = true
        
        do {
            let workouts = try await workoutRepository.fetchWorkouts()
            self.recentWorkouts = workouts
            
            // Calculate macros based on recent activity
            calculateCurrentMetrics(from: workouts)
            
            // Run the AI Prediction Engine for next workout
            self.aiRecommendedTonnage = FatiguePredictionEngine.shared.predictRecommendedTonnage(recentWorkouts: workouts)
            
        } catch {
            print("Data fetch error: \(error)")
        }
        
        isLoading = false
    }
    
    private func calculateCurrentMetrics(from workouts: [WorkoutEntity]) {
        guard let lastWorkout = workouts.first,
              let sets = lastWorkout.exercises?.allObjects.flatMap({ ($0 as? ExerciseEntity)?.sets?.allObjects as? [SetEntity] ?? [] }) else {
            return
        }
        
        let currentTonnage = optimizationEngine.calculateTonnage(for: sets)
        let targetTonnage: Double = 10000.0 // In a real scenario, fetch this from UserEntity
        
        self.dailyProteinTarget = optimizationEngine.calculateDynamicProteinTarget(currentVolume: currentTonnage, targetVolume: targetTonnage)
    }
}
