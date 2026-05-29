import Foundation
import CoreML

final class FatiguePredictionEngine {
    static let shared = FatiguePredictionEngine()
    
    private init() {}
    
    // Note: This expects a compiled Core ML model named "FatigueRegressor.mlmodel" in your Xcode project.
    // We mock the calculation here so the architecture works immediately even without the model file.
    func predictRecommendedTonnage(recentWorkouts: [WorkoutEntity]) -> Double {
        guard !recentWorkouts.isEmpty else {
            return 10000.0 // Default baseline tonnage
        }
        
        // Feature Engineering: Extracting relevant inputs for the ML Model
        let totalRecentTonnage = recentWorkouts.prefix(3).reduce(0) { $0 + $1.totalTonnage }
        let averageRPE = recentWorkouts.prefix(3).compactMap { getRPE(from: $0) }.reduce(0, +) / 3.0
        
        /*
         REAL CORE ML INTEGRATION LOOKS LIKE THIS:
         do {
             let config = MLModelConfiguration()
             let model = try FatigueRegressor(configuration: config)
             let input = FatigueRegressorInput(recentTonnage: totalRecentTonnage, avgRPE: averageRPE)
             let prediction = try model.prediction(input: input)
             return prediction.recommendedTonnage
         } catch {
             print("Core ML Error: \(error)")
             return calculateHeuristicTonnage(totalRecentTonnage)
         }
         */
        
        // Mocking the AI output for testing purposes
        return calculateHeuristicTonnage(totalRecentTonnage: totalRecentTonnage, avgRPE: averageRPE)
    }
    
    // Fallback heuristic function if ML model fails or is not yet imported
    private func calculateHeuristicTonnage(totalRecentTonnage: Double, avgRPE: Double) -> Double {
        let baseTarget = 12000.0
        if avgRPE > 8.5 {
            // High fatigue detected, recommend lighter session
            return baseTarget * 0.8
        }
        return baseTarget
    }
    
    // Helper function to extract RPE from a workout's sets
    private func getRPE(from workout: WorkoutEntity) -> Double? {
        guard let exercises = workout.exercises?.allObjects as? [ExerciseEntity],
              let firstExercise = exercises.first,
              let sets = firstExercise.sets?.allObjects as? [SetEntity],
              let firstSet = sets.first else {
            return nil
        }
        return firstSet.rpe
    }
}
